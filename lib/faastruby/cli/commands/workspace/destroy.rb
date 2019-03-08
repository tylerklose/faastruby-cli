module FaaStRuby
  module Command
    module Workspace
      # require 'faastruby/cli/commands/workspace/base_command'
      require 'faastruby/cli/new_credentials'
      class Destroy < BaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          parse_options
          load_credentials
        end

        def run
          warning unless @options['force']
          FaaStRuby::CLI.error("Cancelled") unless @options['force'] == 'y'
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          spinner = spin("Destroying...")
          workspace.destroy
          if workspace.errors.any?
            spinner.stop(" Failed :(")
            FaaStRuby::CLI.error(workspace.errors)
          end
          spinner.stop("Done!")
          puts "Workspace '#{@workspace_name}' was deleted from the server"
        end

        private

        def warning
          print "WARNING: ".red
          puts "This action will permanently remove the workspace '#{@workspace_name}' and all its functions from the server."
          print "Are you sure? [y/N] "
          @options['force'] = STDIN.gets.chomp
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: WORKSPACE_NAME".red
            @missing_args << "Usage: faastruby destroy-workspace WORKSPACE_NAME"
          end
          FaaStRuby::CLI.error(["'#{@args.first}' is not a valid workspace name.".red, usage], color: nil) if @args.first =~ /^-.*/
          @missing_args
        end

        def self.help
          "destroy-workspace WORKSPACE_NAME [ARGS]"
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
-y,--yes    # Don't prompt for confirmation
          )
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-y'
              @options['force'] = 'y'
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end
      end
    end
  end
end
