module FaaStRuby
  module Command
    module Workspace
      class Destroy < WorkspaceBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          parse_options
          FaaStRuby::Credentials.load_for(@workspace_name)
          @options['credentials_file'] ||= FaaStRuby.credentials_file
        end

        def run
          warning unless @options['force']
          FaaStRuby::CLI.error("Cancelled") unless @options['force'] == 'y'
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          spinner = spin("Destroying...")
          workspace.destroy
          FaaStRuby::CLI.error(workspace.errors) if workspace.errors.any?
          spinner.stop("Done!")
          FaaStRuby::Credentials.remove(@workspace_name, @options['credentials_file'])
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
          "destroy-workspace".light_cyan + " WORKSPACE_NAME [-y, --yes]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
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
