require 'open3'
module FaaStRuby
  module Command
    module Project
      require 'faastruby/cli/commands/project/base_command'
      require 'faastruby/server/logger'
      class Deploy < ProjectBaseCommand
        extend FaaStRuby::Logger
        def initialize(args)
          @errors = []
          @args = args
          parse_options
          @options['functions'] += find_functions unless @options['functions'].any?
          @options['environment'] ||= 'stage'
          @project_yaml = YAML.load(File.read(PROJECT_YAML_FILE)) rescue FaaStRuby::CLI.error("Could not find file 'project.yml'. Are you running this command from the project's folder?")
          @options['root_to'] ||= @project_yaml['root_to']
          @options['error_404_to'] ||= @project_yaml['error_404_to']
        end

        def run
          result = []
          errors = false
          root_folder = Dir.pwd
          jobs = []
          @options['functions'].each do |function_path|
            jobs << Thread.new do
              # puts "[#{function_path}] Entering folder '#{function_path}'"
              # Dir.chdir function_path
              cmd = "cd #{function_path} && faastruby deploy-to #{@project_yaml['name']}-#{@options['environment']}"
              cmd += " --set-root" if @options['root_to'] == function_path
              cmd += " --set-404" if @options['error_404_to'] == function_path
              Open3.popen2(cmd) do |stdin, stdout, status_thread|
                stdout.each_line do |line|
                  puts line
                end
                FaaStRuby::CLI.error("* [#{function_path}] Deploy FAILED", color: nil) unless status_thread.value.success?
              end
            end
          end
          jobs.each{|thr| thr.join}
        end

        def find_functions
          Dir.glob("**/faastruby.yml").map do |f|
            path = f.split('/')
            path.pop
            path.join('/')
          end
        end

        def self.help
          "deploy".light_cyan + " [-f FUNCTION1] [-f FUNCTION2] [-e ENVIRONMENT]   # Deploy all or some functions in the project. ENVIRONMENT defaults to 'stage'."
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        def parse_options
          @options = {'functions' => []}
          while @args.any?
            option = @args.shift
            case option
            when '--root-to'
              @options['root_to'] = @args.shift
            when '--error-404-to'
              @options['error_404_to'] = @args.shift
            when '--function', '-f'
              @options['functions'] << @args.shift
            when '--environment', '-e'
              @options['environment'] = @args.shift
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end

      end
    end
  end
end
