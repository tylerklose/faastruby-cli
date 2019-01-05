module FaaStRuby
  module Command
    module Workspace
      class Deploy < WorkspaceBaseCommand
        def initialize(args)
          @errors = []
          if args.any?
            @args = args
          else
            @args = Dir.glob('*').select{|f| File.directory?(f)}
          end
        end

        def run
          result = []
          errors = false
          @args.each do |workspace|
            Dir.chdir workspace
            functions = Dir.glob('*').select{|f| File.directory?(f)}
            functions.each do |function|
              puts "[deploy] Entering folder #{workspace}/#{function}"
              Dir.chdir function
              if system("faastruby deploy-to #{workspace}")
                result << "* #{workspace}/#{function} [Deploy OK]".green
              else
                result << "* #{workspace}/#{function} [Deploy FAILED]".red
                errors = true
              end
              Dir.chdir '..'
            end
            Dir.chdir '..'
          end
          puts "\nResult:"
          FaaStRuby::CLI.error(result, color: nil) if errors
          puts result
          exit 0
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
