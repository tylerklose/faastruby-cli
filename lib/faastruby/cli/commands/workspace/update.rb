module FaaStRuby
  module Command
    module Workspace
      # require 'faastruby/cli/commands/workspace/base_command'
      require 'faastruby/cli/new_credentials'
      class Update < BaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          parse_options
          load_credentials
        end

        def run(create_directory: true, exit_on_error: true)
          spinner = spin("Updating the number of runners to #{@options['runners_max']}...")
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          workspace.update_runners(@options['runners_max'])
          FaaStRuby::CLI.error(workspace.errors) if workspace.errors.any?
          spinner.stop("Done!")
        end

        def self.help
          "update-workspace WORKSPACE_NAME ARGS"
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
--runners N   # Assign N runners to the workspace.
          )
        end

        private

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: WORKSPACE_NAME".red
            @missing_args << usage
          end
          FaaStRuby::CLI.error(["'#{@args.first}' is not a valid workspace name.".red, usage], color: nil) if @args.first =~ /^-.*/
          @missing_args
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '--runners'
              @options['runners_max'] = @args.shift
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end
      end
    end
  end
end
