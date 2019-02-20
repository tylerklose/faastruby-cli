module FaaStRuby
  module Command
    module Project
      class Deploy < ProjectBaseCommand
        def initialize(args)
          @errors = []
          @args = args
          parse_options
          @options['functions'] += find_functions unless @options['functions'].any?
          @options['environment'] ||= 'stage'
          @project_yaml = YAML.load(File.read(PROJECT_YAML_FILE))
        end

        def run
          result = []
          errors = false
          root_folder = Dir.pwd
          pids = []
          @options['functions'].each do |function_path|
            pids << fork do
              puts "[#{function_path}] [deploy] Entering folder #{function_path}"
              Dir.chdir function_path
              if system("faastruby deploy-to #{@project_yaml['name']}-#{@options['environment']}")
                puts "* [#{function_path}] Deploy OK".green
              else
                FaaStRuby::CLI.error("* [#{function_path}] Deploy FAILED", color: nil)
              end
              Dir.chdir root_folder
            end
          end
          Process.waitall
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
