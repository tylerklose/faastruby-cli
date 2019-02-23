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

    def self.watch_for_live_compile(functions)
      functions.each do |path|
        watch_function_for_live_compile(path)
      end
    end

    def self.watch_function_for_live_compile(path)
      function_folder = File.expand_path path
      add_thread(function_folder, 'watcher', start_watcher_for(function_folder))
      # This will force compile when the server starts
      trigger("#{function_folder}/faastruby.yml")
    end

    def self.start_watcher_for(function_folder)
      function_name = get_function_name(function_folder)
      puts "#{tag} Watching function '#{function_name}' for changes."
      exclude_from_watcher = [
        "#{function_folder}/handler",
        "#{function_folder}/handler.dwarf",
        "#{function_folder}/.package.zip"
      ]
      new_watcher_thread(function_folder, exclude_from_watcher, function_name)
    end

    def self.new_watcher_thread(function_folder, exclude_from_watcher, function_name)
      Thread.new do
        handler_path = get_handler_path_in(function_folder)
        Filewatcher.new(function_folder, exclude: exclude_from_watcher).watch do |filename, event|
          puts "#{tag} Previous Job for '#{function_name}' aborted" if kill_thread_if_alive(function_folder, 'running', function_name)
          if event == :deleted && is_a_function?(filename, function_folder)
            puts "#{tag} Disabling watcher for function '#{function_name}'."
            Thread.kill(get_thread(function_folder, 'watcher'))
            next
          end
          add_thread(function_folder, 'running', Thread.new {CrystalBuild.new(function_folder, handler_path, run_before_build: true).start})
        end
      end
    end

    def self.detect_new_functions(target, language)
      Thread.new do
        puts "#{tag} Watching for new #{language} functions..."
        Filewatcher.new(target).watch do |full_path, event|
          next unless event == :created
          file = File.basename(full_path)
          function_folder = File.dirname(full_path)
          function_name = get_function_name(function_folder)
          yield(function_folder, file, full_path, function_name)
          enable_sync_for(function_folder, delay: 1) if ENV['SYNC']
        end
      end

    end

    def self.start_crystal(functions)
      puts "#{tag} Crystal functions: #{functions}"
      enable_sync(functions, delay: 1) if ENV['SYNC']
      watch_for_live_compile(functions)
      detect_new_functions("#{PROJECT_ROOT}/**/handler.cr", 'Crystal') do |function_folder, file, full_path, function_name|
        function_folder = normalize_crystal_folder(function_folder)
        add_configuration(function_folder, file, full_path)
        puts "#{tag} New Crystal function detected at '#{function_name}'."
        write_handler(full_path, 'crystal')
        add_thread(function_folder, 'watcher', start_watcher_for(function_folder))
        # trigger(full_path)
      end
    end

    def self.start_ruby(functions)
      puts "#{tag} Ruby functions: #{functions}"
      enable_sync(functions) if ENV['SYNC']
      detect_new_functions("#{PROJECT_ROOT}/**/handler.rb", 'Ruby') do |function_folder, file, full_path, function_name|
        add_configuration(function_folder, file, full_path)
        puts "#{tag} New Ruby function detected at '#{function_name}'."
        write_handler(full_path, 'ruby')
      end
    end

    def self.enable_sync(functions, delay: nil)
      functions.each do |path|
        function_folder = File.expand_path path
        enable_sync_for(function_folder, delay: delay)
      end
    end

    def self.enable_sync_for(function_folder, delay: nil)
      add_thread(function_folder, 'sync', start_sync_for(function_folder, delay: delay))
    end

    def self.start!
      functions = find_functions
      puts "#{tag} Sync mode enabled. Your functions will be auto-deployed to the workspace '#{WORKSPACE}'." if ENV['SYNC']
      start_ruby(functions['ruby']) if RUBY_ENABLED
      start_crystal(functions['crystal']) if CRYSTAL_ENABLED
    end

    def self.normalize_crystal_folder(function_folder)
      if function_folder.match(/src$/) && File.file?("#{function_folder}/../faastruby.yml") && File.file?("#{function_folder}/handler.cr")
        function_folder.sub!(/\/src$/, '')
      end
      function_folder
    end

    def self.write_handler(filename, runtime)
      content = "def handler(event)\n  # Write code here\n  \nend" if runtime == 'ruby'
      content = "def handler(event : FaaStRuby::Event) : FaaStRuby::Response\n  # Write code here\n  \nend" if runtime == 'crystal'
      File.write(filename, content)
    end

    def self.get_function_name(function_folder)
      (function_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
    end

    def self.add_configuration(function_folder, file, filename)
      if File.file?("#{function_folder}/faastruby.yml")
        merge_yaml(function_folder, runtime: default_runtime(file))
      else
        write_yaml(function_folder, runtime: default_runtime(file))
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
      function_name = get_function_name(function_folder)
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

    def self.start_sync_for(function_folder, delay: nil)
      # function_name = get_function_name(function_folder)
      # puts "#{tag} Sync activated for function '#{function_name}'."
      Thread.new do
        start_sync(function_folder, delay: delay)
      end
    end

    def self.remove_from_cloud(function_name, function_folder)
      remove_cmd = ["faastruby", "remove-from", WORKSPACE, "-y", "-f", function_name]
      removed = system(*remove_cmd)
      add_thread(function_folder, 'deployed', nil)
      if removed
        puts "#{tag} Function '#{function_name}' was removed from the cloud."
      else
        puts "#{tag} The workspace '#{WORKSPACE}' had no function named '#{function_name}', please ignore the message in red."
      end
    end

    def self.kill_thread_if_alive(function_folder, kind, function_name)
      thr = get_thread(function_folder, kind)
      if thr&.alive?
        Thread.kill(thr)
        return true
      end
      return false
    end

    def self.start_sync(function_folder, delay: nil)
      sleep delay if delay
      function_name = get_function_name(function_folder)
      Filewatcher.new("#{function_folder}/", exclude: ["#{function_folder}/handler", "#{function_folder}/handler.dwarf", "#{function_folder}/.package.zip"]).watch do |filename, event|
        puts "#{tag} Previous Deploy for '#{function_name}' aborted" if kill_thread_if_alive(function_folder, 'deploying', function_name)
        if event == :deleted && is_a_function?(filename, function_folder)
          remove_from_project(function_folder, function_name)
          next
        end
        deploy_cmd, deploy_cmd_print = generate_deploy_command(function_name, function_folder)
        puts "#{tag} Running: #{deploy_cmd_print.join(' ')}"
        deploy(function_folder, deploy_cmd)
      end
    end

    def self.is_a_function?(filename, function_folder)
      filename == function_folder || filename.match(/#{function_folder}\/(handler\.(rb|cr)|faastruby.yml)/)
    end

    def self.remove_from_project(function_folder, function_name)
      Thread.kill(get_thread(function_folder, 'sync'))
      add_thread(function_folder, 'sync', nil)
      puts "#{tag} Function '#{function_name}' was removed from the project."
      remove_from_cloud(function_name, function_folder)# if get_thread(function_folder, 'deployed')
    end

    def self.deploy(function_folder, deploy_cmd)
      add_thread(function_folder, 'deploying', Thread.new {system(*deploy_cmd)})
      add_thread(function_folder, 'deployed', true)
    end

    def self.generate_deploy_command(function_name, function_folder)
      project_config = YAML.load(File.read("project.yml"))
      deploy_cmd = ['faastruby', 'deploy-to', WORKSPACE, '-f', function_name]
      deploy_cmd << '--set-root' if project_config['root_to'] == function_name
      deploy_cmd << '--set-404' if project_config['error_404_to'] == function_name
      secrets_json = Oj.dump(
        YAML.load(
          File.read("secrets.yml")
        )['secrets'][function_name]
      ) rescue nil
      deploy_cmd_print = deploy_cmd
      if secrets_json
        deploy_cmd += ["--context", secrets_json]
        deploy_cmd_print += ["--context", '*REDACTED*']
      end
      [deploy_cmd, deploy_cmd_print]
    end

    def self.get_handler_path_in(function_folder)
      if File.file?("#{function_folder}/handler.cr")
        "#{function_folder}/handler"
      else
        "#{function_folder}/src/handler"
      end
    end

    def self.check_for_yaml_file(function_folder, handler_file)
      yaml_file = "#{function_folder}/faastruby.yml"
      unless File.file?(yaml_file)
        puts "#{tag} Function '#{function_folder}' did not have a YML configuration file."
        write_yaml(function_folder, runtime: default_runtime(File.basename(handler_file)), original: nil)
      end
      YAML.load(File.read yaml_file)
    end

    def self.find_functions
      crystal_functions = []
      ruby_functions = []
      Dir.glob(["**/handler.rb", "**/handler.cr"]).each do |handler_file|
        function_folder = File.dirname(handler_file)
        function_folder.sub!(/\/src$/, '') if handler_file.match(/src\/handler\.cr$/)
        yaml = check_for_yaml_file(function_folder, handler_file)
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
    def initialize(directory, handler_path, run_before_build: false)
      @directory = directory
      @function_name = Sentinel.get_function_name(directory)
      @runtime_path = Pathname.new "#{Gem::Specification.find_by_name("faastruby").gem_dir}/lib/faastruby/server/crystal_runtime.cr"
      h_path = Pathname.new(handler_path)
      @handler_path = h_path.relative_path_from @runtime_path
      @env = {'HANDLER_PATH' => @handler_path.to_s}
      @run_before_build = run_before_build
      @crystal_build = "cd #{@directory} && crystal build #{@runtime_path} -o handler"
    end

    def pre_compile_list
      return [] unless @run_before_build
      YAML.load(File.read("#{@directory}/faastruby.yml"))["before_build"] || []
    end

    def precompile
      pre_compile_list.each do |cmd|
        cmd = "cd #{@directory} && #{cmd}"
        puts "#{tag} Job ID=\"#{job_id}\" running before_build: '#{cmd}'"
        output, status = Open3.capture2e(cmd)
        success = status.exitstatus == 0
        unless success
          puts "#{tag} #{output}"
          puts "#{tag} Job ID=\"#{job_id}\" failed: #{status}"
          return false
        end
      end
      return true
    end

    def start
      Thread.report_on_exception = false
      job_id = SecureRandom.uuid
      puts "#{tag} Job ID=\"#{job_id}\" started: " + "Compiling function '#{@function_name}'"
      return false unless precompile
      output, status = Open3.capture2e(@env, @crystal_build)
      success = status.exitstatus == 0
      puts "#{tag} #{output}" unless success
      puts "#{tag} Job ID=\"#{job_id}\" #{success ? 'completed' : 'failed'}: #{status}"
    end
  end
end