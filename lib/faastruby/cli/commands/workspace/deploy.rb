module FaaStRuby
  module Command
    module Workspace
      class Deploy < WorkspaceBaseCommand
        def initialize(args)
          @errors = []
          if args.any?
            @args = args
          else
            @args = find_functions
          end
          @workspace_yaml = YAML.load(File.read('faastruby-workspace.yml'))
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
              if system("faastruby deploy-to #{@workspace_yaml['name']}")
                puts "* [#{function_path}] Deploy OK".green
              else
                # puts "* [#{function_path}] Deploy FAILED".red
                # errors = true
                FaaStRuby::CLI.error("* [#{function_path}] Deploy FAILED", color: nil)
              end
              Dir.chdir root_folder
            end
          end
          Process.waitall
          # puts "\nResult:"
          # FaaStRuby::CLI.error(result, color: nil) if errors
          # puts result
          # exit 0
        end

        def find_functions
          Dir.glob("**/faastruby.yml").map do |f|
            path = f.split('/')
            path.pop
            path.join('/')
          end
        end

        def self.help
          "deploy".light_cyan + " [WORKSPACE_FOLDER1] [WORKSPACE_FOLDER2]...    # Deploy all workspaces in the current directory and their functions"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

      end
    end
  end
end
