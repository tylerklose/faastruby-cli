module FaaStRuby
  module Command
    module Workspace
      class Create < WorkspaceBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          parse_options
          @options['credentials_file'] ||= FaaStRuby.credentials_file
        end

        def run
          spinner = spin("Requesting credentials...")
          workspace = FaaStRuby::Workspace.create(name: @workspace_name, email: @options['email'])
          spinner.stop("Done!")
          FaaStRuby::CLI.error(workspace.errors) if workspace.errors.any?
          if @options['stdout']
            puts "IMPORTANT: Please store the credentials below in a safe place. If you lose them you will not be able to manage your workspace.".yellow
            puts "API_KEY: #{workspace.credentials['api_key']}"
            puts "API_SECRET: #{workspace.credentials['api_secret']}"
          else
            puts "Writing credentials to #{@options['credentials_file']}"
            FaaStRuby::Credentials.add(@workspace_name, workspace.credentials, @options['credentials_file'])
          end
          puts "Workspace '#{@workspace_name}' created"
        end

        def self.help
          "create-workspace".blue + " WORKSPACE_NAME [--stdout|-c, --credentials-file CREDENTIALS_FILE] [-e, --email YOUR_EMAIL_ADDRESS]"
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

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            # when '--file'
            #   @options['credentials_file'] = @args.shift
            when '--stdout'
              @options['stdout'] = true
            when '-c', '--credentials-file'
              @options['credentials_file'] = @args.shift
            when '-e', '--email'
              @options['email'] = @args.shift
            else
              FaaStRuby.error("Unknown argument: #{option}")
            end
          end
        end
      end
    end
  end
end
