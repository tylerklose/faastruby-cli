module FaaStRuby
  module Command
    module Project
      class Deploy < ProjectBaseCommand
        def initialize(args)
          @errors = []
          if args.any?
            @args = args
          else
            @args = find_functions
          end
          @project_yaml = YAML.load(File.read(PROJECT_YAML_FILE))
        end

        def run
          result = []
          errors = false
          root_folder = Dir.pwd
          pids = []
          @args.each do |function_path|
            pids << fork do
              puts "[#{function_path}] [deploy] Entering folder #{function_path}"
              Dir.chdir function_path
              if system("faastruby deploy-to #{@project_yaml['name']}")
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
          "deploy".light_cyan + " [FUNCTION1] [FUNCTION2]    # Deploy all or some functions in the project."
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

      end
    end
  end
end
