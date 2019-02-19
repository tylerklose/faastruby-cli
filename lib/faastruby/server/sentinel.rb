# Here 'project_folder' is the function folder.
require 'open3'
require 'tempfile'
require 'pathname'
module FaaStRuby
  module Sentinel
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
    def self.start!
      find_crystal_projects.each do |path|
        project_folder = File.expand_path path
        add_thread(project_folder, 'watcher', start_watcher_for(project_folder))
        # This will force compile when the server starts
        trigger("#{project_folder}/faastruby.yml")
      end
      
      # watch for new projects
      Thread.new do
        puts "#{Time.now} [WatchDog] Watching for new functions...".yellow
        Filewatcher.new(["#{PROJECT_ROOT}/**/handler.cr", "#{PROJECT_ROOT}/**/handler.rb"]).watch do |filename, event|
          path = filename.split('/')
          file = path.pop
          project_folder = path.join('/')
          sleep 1
          if project_folder.match(/src$/) && File.file?("#{project_folder}/../faastruby.yml") && File.file?("#{project_folder}/handler.cr")
            project_folder.sub!(/\/src$/, '') 
            trigger_compile = true
          end
          if event == :created 
            unless File.file?("#{project_folder}/faastruby.yml")
              write_yaml(project_folder, runtime: default_runtime(file))
            end
            case file
            when 'handler.cr'
              puts "#{Time.now} [WatchDog] New Crystal function detected at '#{project_folder}'.".yellow
              add_thread(project_folder, 'watcher', start_watcher_for(project_folder))
              trigger(filename) if trigger_compile
            when 'handler.rb'
              puts "#{Time.now} [WatchDog] New Ruby function detected at '#{project_folder}'.".yellow
              puts "#{Time.now} [WatchDog] File created: '#{project_folder}/faastruby.yml'".yellow
            end
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
    def self.write_yaml(project_folder, runtime:)
      function_name = (project_folder.split('/') - PROJECT_ROOT.split('/')).join('/')
      hash = {
        'cli_version' => FaaStRuby::VERSION,
        'name' => function_name,
        'runtime' => runtime
      }
      File.write("#{project_folder}/faastruby.yml", hash.to_yaml)
      puts "#{Time.now} [WatchDog] File created: '#{project_folder}/faastruby.yml'".yellow
    end
    def self.start_watcher_for(project_folder)
      puts "#{Time.now} [Watchdog] Watching function '#{project_folder}' for changes.".yellow
      Thread.new do
        handler_path = File.file?("#{project_folder}/handler.cr") ? "#{project_folder}/handler" : "#{project_folder}/src/handler" 
        Filewatcher.new("#{project_folder}/", exclude: ["#{project_folder}/handler", "#{project_folder}/handler.dwarf"]).watch do |filename, event|
          thr = get_thread(project_folder)['running']
          if thr&.alive?
            Thread.kill(thr)
            puts "#{Time.now} [WatchDog] Previous Job for '#{project_folder}' aborted".yellow
          end
          if event == :deleted
            puts "#{Time.now} [WatchDog] Function '#{project_folder}' deleted. Disabling watcher.".yellow
            Thread.kill(get_thread(project_folder)['watcher'])
            next
          end
          add_thread(project_folder, 'running', Thread.new {CrystalBuild.new(project_folder, handler_path, before_build: true).start})
        end
      end
    end

    def self.find_crystal_projects
      directories = Dir.glob('**/faastruby.yml').map do |yaml_file|
        base_dir = yaml_file.split('/')
        base_dir.pop
        yaml = YAML.load(File.read yaml_file)
        yaml['runtime']&.match(/^crystal:/) ? base_dir.join('/') : nil
      end
      directories.compact
    end
  end
  class CrystalBuild
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
      puts "#{Time.now} [WatchDog] Job #{job_id} started: ".yellow + "Compiling function #{@directory}"
      @pre_compile.each do |cmd|
        puts "#{Time.now} [WatchDog] Job #{job_id} running before_build: ".yellow + cmd
        output, status = Open3.capture2e(cmd)
        success = status.exitstatus == 0
        unless success
          puts output
          puts "#{Time.now} [WatchDog] Job #{job_id} failed: ".yellow + status.to_s   
          return false
        end
      end
      output, status = Open3.capture2e(@env, @cmd)
      success = status.exitstatus == 0
      puts output unless success
      puts "#{Time.now} [WatchDog] Job #{job_id} #{success ? 'completed' : 'failed'}: ".yellow + status.to_s   
    end
  end
end