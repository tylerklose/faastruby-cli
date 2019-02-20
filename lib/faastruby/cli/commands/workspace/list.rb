module FaaStRuby
  module Command
    module Workspace
      class List < WorkspaceBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          FaaStRuby::Credentials.load_for(@workspace_name)
        end

        def run
          workspace = FaaStRuby::Workspace.new(name: @workspace_name).fetch
          FaaStRuby::CLI.error(workspace.errors) if workspace.errors.any?
          puts "Allocated Runners: #{workspace.runners_max} (disabled)" if workspace&.runners_max == 0
          puts "Allocated Runners: #{workspace.runners_max}" if workspace&.runners_max > 0
          print_functions_table(workspace.functions)
        end

        def print_functions_table(functions)
          no_functions unless functions.any?
          rows = functions.map do |hash|
            [hash['name'], hash['endpoint']]
          end
          table = TTY::Table.new(['FUNCTION','ENDPOINT'], rows)
          puts table.render(:basic)
        end

        def self.help
          "list-workspace".light_cyan + " WORKSPACE_NAME"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
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

        def no_functions
          puts "The workspace '#{@workspace_name}' has no functions."
          exit 0
        end
      end
    end
  end
end
