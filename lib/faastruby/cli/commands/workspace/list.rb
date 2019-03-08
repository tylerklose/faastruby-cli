require 'tty-table'
module FaaStRuby
  module Command
    module Workspace
      # require 'faastruby/cli/commands/workspace/base_command'
      require 'faastruby/cli/new_credentials'
      class List < BaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          load_credentials
        end

        def run
          workspace = FaaStRuby::Workspace.new(name: @workspace_name).fetch
          FaaStRuby::CLI.error(workspace.errors) if workspace.errors.any?
          if workspace.runners_max
            puts "Allocated Runners: #{workspace.runners_max} (disabled)" if workspace&.runners_max == 0
            puts "Allocated Runners: #{workspace.runners_max}" if workspace&.runners_max > 0
          end
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
          "list-workspace WORKSPACE_NAME"
        end

        def usage
          puts "\n# List the contents of a cloud workspace."
          puts "\nUsage: faastruby #{self.class.help}\n\n"
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
