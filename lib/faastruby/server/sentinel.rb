# Here 'function_folder' is the function folder.
require 'open3'
require 'tempfile'
require 'pathname'
module FaaStRuby
  module Sentinel
    extend FaaStRuby::Logger::System
    @@threads = {}
    MUTEX = Mutex.new
    def self.add_thread(project, key, value)
      MUTEX.synchronize do
        @@threads[project] ||= {}
        @@threads[project][key] = value
      end
    end
    def self.get_thread(project)
      MUTEX.synchronize do
        @@threads[project]
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
      projects = find_projects
      if ENV['SYNC']
        projects['ruby'].each do |path|
          function_folder = File.expand_path path
          add_thread(function_folder, 'sync', start_sync_for(function_folder, runtime: 'ruby'))
        end
      end
      projects['crystal'].each do |path|
        function_folder = File.expand_path path
        add_thread(function_folder, 'watcher', start_watcher_for(function_folder))
        add_thread(function_folder, 'sync', start_sync_for(function_folder, runtime: 'crystal')) if ENV['SYNC']
        # This will force compile when the server starts
        trigger("#{function_folder}/faastruby.yml")
      end

      # watch for new projects
      Thread.new do
        puts "#{tag} Watching for new functions..."
        Filewatcher.new(["#{PROJECT_ROOT}/**/handler.cr", "#{PROJECT_ROOT}/**/handler.rb"]).watch do |filename, event|
          path = filename.split('/')
          file = path.pop
          function_folder = path.join('/')
          sleep 1
          if function_folder.match(/src$/) && File.file?("#{function_folder}/../faastruby.yml") && File.file?("#{function_folder}/handler.cr")
            function_folder.sub!(/\/src$/, '')
            trigger_compile = true
          end
          if event == :created
            if File.file?("#{function_folder}/faastruby.yml")
              merge_yaml(function_folder, runtime: default_runtime(file))
            else
              write_yaml(function_folder, runtime: default_runtime(file))
            end
            case file
            when 'handler.cr'
              puts "#{tag} New Crystal function detected at '#{function_folder}'."

              add_thread(function_folder, 'watcher', start_watcher_for(function_folder))
              add_thread(function_folder, 'sync', start_sync_for(function_folder, runtime: 'crystal')) if ENV['SYNC']
              trigger(filename) if trigger_compile
            when 'handler.rb'
              puts "#{tag} New Ruby function detected at '#{function_folder}'."
              add_thread(function_folder, 'sync', start_sync_for(function_folder, runtime: 'ruby')) if ENV['SYNC']
            end
            puts "#{tag} File created: '#{function_folder}/faastruby.yml'"
          end
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
        sleep 1
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
      puts "#{tag} File created: '#{function_folder}/faastruby.yml'"
    end

    def self.start_sync_for(function_folder, runtime:)
      puts "#{tag} Sync activated for function '#{function_folder}'."
      Thread.new do
        case runtime
        when 'ruby'
          RubySync.new(function_folder).start
        when 'crystal'
          CrystalSync.new(function_folder).start
        end
      end
    end

    def self.start_watcher_for(function_folder)
      puts "#{tag} Watching function '#{function_folder}' for changes."
      Thread.new do
        handler_path = File.file?("#{function_folder}/handler.cr") ? "#{function_folder}/handler" : "#{function_folder}/src/handler"
        Filewatcher.new("#{function_folder}/", exclude: ["#{function_folder}/handler", "#{function_folder}/handler.dwarf"]).watch do |filename, event|
          thr = get_thread(function_folder)['running']
          if thr&.alive?
            Thread.kill(thr)
            puts "#{tag} Previous Job for '#{function_folder}' aborted"
          end
          if event == :deleted
            puts "#{tag} Function '#{function_folder}' deleted. Disabling watcher."
            Thread.kill(get_thread(function_folder)['watcher'])
            next
          end
          add_thread(function_folder, 'running', Thread.new {CrystalBuild.new(function_folder, handler_path, before_build: true).start})
        end
      end
    end

    def self.find_projects
      crystal_functions = []
      ruby_functions = []
      directories = Dir.glob('**/faastruby.yml').each do |yaml_file|
        base_dir = yaml_file.split('/')
        base_dir.pop
        yaml = YAML.load(File.read yaml_file)
        dir = base_dir.join('/')
        case yaml['runtime']
        when /^crystal:/
          crystal_functions << dir
        when /^ruby:/
          ruby_functions << dir
        end
      end
      {'crystal' => crystal_functions, 'ruby' => ruby_functions}
    end
  end
  class CrystalBuild
    include FaaStRuby::Logger::System
    def initialize(directory, handler_path, before_build: false)
      @directory = directory
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
      puts "#{tag} Job ID=\"#{job_id}\" started: " + "Compiling function '#{@directory}'"
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

  class CrystalSync

    def start
    end
  end

  class RubySync
    def initialize(function_folder)
    end

    def start
    end
  end
end