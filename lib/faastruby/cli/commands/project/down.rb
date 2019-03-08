require 'open3'
module FaaStRuby
  module Command
    STDOUT_MUTEX = Mutex.new
    module Project
      require 'faastruby/cli/commands/project/base_command'
      require 'faastruby/server/logger'
      class Down < ProjectBaseCommand
        extend FaaStRuby::Logger
        def initialize(args)
          @args = args
          help
          parse_options
          @options['environment'] ||= 'stage'
          @project_yaml = YAML.load(File.read(PROJECT_YAML_FILE))['project'] rescue FaaStRuby::CLI.error("Could not find file 'project.yml'. Are you running this command from the project's folder?")
          @project_name = @project_yaml['name']
          @project_identifier = "-#{@project_yaml['identifier']}" if @project_yaml['identifier']
        end

        def run
          workspace = "#{@project_name}-#{@options['environment']}#{@project_identifier}"
          if @options['force']
            exec("faastruby destroy-workspace #{workspace} -y")
          else
            exec("faastruby destroy-workspace #{workspace}")
          end
        end

        def self.help
          "down [ARGS]"
        end

        def usage
          puts "Usage: faastruby #{self.class.help}"
          puts %(
-e,--env ENVIRONMENT           # ENVIRONMENT is added to the project name to compose the workspace name.
          )
        end

        def parse_options
          @options = {'functions' => []}
          while @args.any?
            option = @args.shift
            case option
            when '-y', '--yes'
              @options['force'] = true
            when '--env', '-e'
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
