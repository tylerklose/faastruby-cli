# Here 'function_folder' is the function folder.
require 'open3'
require 'tempfile'
require 'pathname'
require 'yaml'
module FaaStRuby
  module Sentinel
    DEPLOY_ENVIRONMENT = ENV['DEPLOY_ENVIRONMENT'] || 'stage'
    PROJECT_NAME = YAML.load(File.read("project.yml"))['name']
    WORKSPACE = "#{PROJECT_NAME}-#{DEPLOY_ENVIRONMENT}"
    extend FaaStRuby::Logger::System
    @@threads = {}
    MUTEX = Mutex.new
    def self.add_thread(function_folder, key, value)
      MUTEX.synchronize do
        @@threads[function_folder] ||= {}
        @@threads[function_folder][key] = value
      end
    end
    def self.get_thread(function_folder, key)
      MUTEX.synchronize do
        return nil if @@threads[function_folder].nil?
        @@threads[function_folder][key]
      end
    end

    def self.get_threads
      MUTEX.synchronize do
        @@threads
      end
    end

    def self.tag
      '(WatchDog)'
    end

    def self.start!
      functions = find_functions
      puts "#{tag} Ruby functions: #{functions['ruby']}"
      puts "#{tag} Crystal functions: #{functions['crystal']}"
      if ENV['SYNC']
        puts "#{tag} Sync mode enabled. Your functions will be auto-deployed to the workspace '#{WORKSPACE}'."
        functions['ruby'].each do |path|
          function_folder = File.expand_path path
          add_thread(function_folder, 'sync', start_sync_for(function_folder))
        end
      end
      functions['crystal'].each do |path|
        function_folder = File.expand_path path
        add_thread(function_folder, 'watcher', start_watcher_for(function_folder))
        # This will force compile when the server starts
        trigger("#{function_folder}/faastruby.yml")
        add_thread(function_folder, 'sync', start_sync_for(function_folder, delay: 1)) if ENV['SYNC']
      end

      # watch for new projects
      Thread.new do
        puts "#{tag} Watching for new functions..."
        Filewatcher.new(["#{PROJECT_ROOT}/**/handler.cr", "#{PROJECT_ROOT}/**/handler.rb"]).watch do |filename, event|
          next unless event == :created
          path = filename.split('/')
          file = path.pop
          function_folder = path.join('/')
          function_name = (function_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
          sleep 0.5
          if function_folder.match(/src$/) && File.file?("#{function_folder}/../faastruby.yml") && File.file?("#{function_folder}/handler.cr")
            function_folder.sub!(/\/src$/, '')
            trigger_compile = true
          end
          # if event == :created
            if File.file?("#{function_folder}/faastruby.yml")
              merge_yaml(function_folder, runtime: default_runtime(file))
            else
              write_yaml(function_folder, runtime: default_runtime(file))
            end
            case file
            when 'handler.cr'
              puts "#{tag} New Crystal function detected at '#{function_name}'."
              File.write(filename, "def handler(event : FaaStRuby::Event) : FaaStRuby::Response\n  # Write code here\n\nend")
              add_thread(function_folder, 'watcher', start_watcher_for(function_folder))
              trigger(filename) if trigger_compile
            when 'handler.rb'
              puts "#{tag} New Ruby function detected at '#{function_name}'."
              File.write(filename, "def handler(event)\n  # Write code here\n\nend")
            end
            add_thread(function_folder, 'sync', start_sync_for(function_folder)) if ENV['SYNC']
          # end
        end
      end
    end

    def self.default_runtime(handler)
      case handler
      when 'handler.rb'
        return DEFAULT_RUBY_RUNTIME
      when 'handler.cr'
        return DEFAULT_CRYSTAL_RUNTIME
      end
    end

    def self.trigger(file)
      Thread.new do
        sleep 0.5
        FileUtils.touch(file)
        Thread.exit
      end
    end
    def self.merge_yaml(function_folder, runtime:)
      yaml = YAML.load(File.read("#{function_folder}/faastruby.yml"))
      write_yaml(function_folder, runtime: runtime, original: yaml)
    end
    def self.write_yaml(function_folder, runtime:, original: nil)
      function_name = (function_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
      hash = {
        'cli_version' => FaaStRuby::VERSION,
        'name' => function_name,
        'runtime' => runtime
      }
      hash = original.merge(hash) if original
      File.write("#{function_folder}/faastruby.yml", hash.to_yaml)
      unless original
        File.open("#{function_folder}/faastruby.yml", 'a') do |f|
          f.write yaml_comments
        end
      end
      puts "#{tag} File created: '#{function_name}/faastruby.yml'"
    end

    def self.yaml_comments
      [
        '## You can add commands to run locally before building the deployment package.',
        "## Some use cases are:",
        "## * minifying Javascript/CSS",
        "## * downloading a file to be included in the package.",
        "# before_build:",
        "#   - curl https://some.url --output some.file",
        "#   - uglifyjs your.js -c -m -o your.min.js",
        '',
        '## To schedule periodic runs, follow the example below:',
        '# schedule:',
        '#   job1:',
        '#     when: every 2 hours',
        '#     body: {"foo": "bar"}',
        '#     method: POST',
        '#     query_params: {"param": "value"}',
        '#     headers: {"Content-Type": "application/json"}',
        '#   job2: ...'
      ].join("\n")
    end

    def self.start_sync_for(function_folder, delay: false)
      function_name = (function_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
      # puts "#{tag} Sync activated for function '#{function_name}'."
      Thread.new do
        start_sync(function_folder, delay: delay)
      end
    end

    def self.start_sync(function_folder, delay: false)
      sleep delay if delay
      function_name = (function_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
      Filewatcher.new("#{function_folder}/", exclude: ["#{function_folder}/handler", "#{function_folder}/handler.dwarf", "#{function_folder}/.package.zip"]).watch do |filename, event|
        thr = get_thread(function_folder, 'deploying')
        if thr&.alive?
          Thread.kill(thr)
          puts "#{tag} Previous Deploy for '#{function_name}' aborted"
        end
        if event == :deleted && (filename == function_folder || filename.match(/#{function_folder}\/(handler\.(rb|cr)|faastruby.yml)/))
          Thread.kill(get_thread(function_folder, 'sync'))
          add_thread(function_folder, 'sync', nil)
          puts "#{tag} Function '#{function_name}' was removed from the project."
          if get_thread(function_folder, 'deployed')
            remove_cmd = ["faastruby", "remove-from", WORKSPACE, "-y", "-f", function_name]
            system(*remove_cmd)
            add_thread(function_folder, 'deployed', nil)
            puts "#{tag} Function '#{function_name}' was removed from the cloud."
          end
          next
        end
        secrets = YAML.load(File.read("secrets.yml"))['secrets'][function_name] rescue nil
        project_config = YAML.load(File.read("project.yml"))
        deploy_cmd = ['faastruby', 'deploy-to', WORKSPACE, '-f', function_name]
        deploy_cmd << '--set-root' if project_config['root_to'] == function_name
        deploy_cmd << '--set-404' if project_config['error_404_to'] == function_name
        if secrets
          secrets_json = Oj.dump(secrets)
          deploy_cmd += ["--context", secrets_json]
        end
        deploy_cmd_display = deploy_cmd.dup
        secret_content = deploy_cmd_display.index('--context') + 1 rescue nil
        deploy_cmd_display[secret_content] = '*REDACTED*' if secret_content
        puts "#{tag} Running: #{deploy_cmd_display.join(' ')}"
        add_thread(function_folder, 'deploying', Thread.new {system(*deploy_cmd)})
        add_thread(function_folder, 'deployed', true)
      end
    end

    def self.start_watcher_for(function_folder)
      function_name = (function_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
      puts "#{tag} Watching function '#{function_name}' for changes."
      Thread.new do
        handler_path = File.file?("#{function_folder}/handler.cr") ? "#{function_folder}/handler" : "#{function_folder}/src/handler"
        Filewatcher.new("#{function_folder}/", exclude: ["#{function_folder}/handler", "#{function_folder}/handler.dwarf", "#{function_folder}/.package.zip"]).watch do |filename, event|
          thr = get_thread(function_folder, 'running')
          if thr&.alive?
            Thread.kill(thr)
            puts "#{tag} Previous Job for '#{function_name}' aborted"
          end
          if event == :deleted && filename == function_folder
            puts "#{tag} Disabling watcher for function '#{function_name}'."
            Thread.kill(get_thread(function_folder, 'watcher'))
            next
          end
          add_thread(function_folder, 'running', Thread.new {CrystalBuild.new(function_folder, handler_path, before_build: true).start})
        end
      end
    end

    def self.find_functions
      crystal_functions = []
      ruby_functions = []
      directories = Dir.glob(["**/handler.rb", "**/handler.cr"]).each do |handler_file|
        function_folder = File.dirname(handler_file)
        function_folder.sub!(/\/src$/, '') if handler_file.match(/src\/handler\.cr$/)
        yaml_file = "#{function_folder}/faastruby.yml"
        unless File.file?(yaml_file)
          puts "#{tag} Function '#{function_folder}' did not have a YML configuration file."
          write_yaml(function_folder, runtime: default_runtime(File.basename(handler_file)), original: nil)
        end
        yaml = YAML.load(File.read yaml_file)
        case yaml['runtime']
        when /^crystal:/
          crystal_functions << function_folder
        when /^ruby:/
          ruby_functions << function_folder
        end
      end
      {'crystal' => crystal_functions, 'ruby' => ruby_functions}
    end
  end
  class CrystalBuild
    include FaaStRuby::Logger::System
    def initialize(directory, handler_path, before_build: false)
      @directory = directory
      @function_name = (directory.split('/') - PROJECT_ROOT.split('/')).join('/')
      @runtime_path = Pathname.new "#{Gem::Specification.find_by_name("faastruby").gem_dir}/lib/faastruby/server/crystal_runtime.cr"
      h_path = Pathname.new(handler_path)
      @handler_path = h_path.relative_path_from @runtime_path
      @env = {'HANDLER_PATH' => @handler_path.to_s}
      @before_build = before_build
      @pre_compile = @before_build ? (YAML.load(File.read("#{directory}/faastruby.yml"))["before_build"] || []) : []
      @cmd = "crystal build #{@runtime_path} -o handler"
    end

    def start
      Thread.report_on_exception = false
      Dir.chdir(@directory)
      job_id = SecureRandom.uuid
      puts "#{tag} Job ID=\"#{job_id}\" started: " + "Compiling function '#{@function_name}'"
      @pre_compile.each do |cmd|
        puts "#{tag} Job ID=\"#{job_id}\" running before_build: '#{cmd}'"
        output, status = Open3.capture2e(cmd)
        success = status.exitstatus == 0
        unless success
          puts "#{tag} #{output}"
          puts "#{tag} Job ID=\"#{job_id}\" failed: #{status}"
          return false
        end
      end
      output, status = Open3.capture2e(@env, @cmd)
      success = status.exitstatus == 0
      puts "#{tag} #{output}" unless success
      puts "#{tag} Job ID=\"#{job_id}\" #{success ? 'completed' : 'failed'}: #{status}"
    end
  end
end