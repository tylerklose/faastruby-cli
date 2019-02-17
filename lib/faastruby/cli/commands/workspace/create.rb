module FaaStRuby
  module Command
    module Workspace
      class Create < WorkspaceBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          @base_dir = "./#{@workspace_name}"
          parse_options
          @options['credentials_file'] ||= FaaStRuby.credentials_file
        end

        def run(create_directory: true, exit_on_error: true)
          unless @options['skip_creation']
            spinner = spin("Requesting credentials...")
            workspace = FaaStRuby::Workspace.create(name: @workspace_name, email: @options['email'])
            if workspace.errors.any? && exit_on_error
              spinner.stop("Error")
              FaaStRuby::CLI.error(workspace.errors)
            end
            spinner.stop("Done!")
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
          create_dir if @options['create_local_dir'] && create_directory && !dir_exists?
        end

        def self.help
          "create-workspace".light_cyan + " WORKSPACE_NAME [--create-local-dir] [--stdout] [-c, --credentials-file CREDENTIALS_FILE] [-e, --email YOUR_EMAIL_ADDRESS]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def create_dir
          FileUtils.mkdir_p(@base_dir)
          puts "+ d #{@base_dir}".green
          File.open("#{@base_dir}/faastruby-workspace.yml", 'w') do |file|
            file.puts "name: #{@workspace_name}"
          end
          puts "+ f #{@base_dir}/faastruby-workspace.yml".green
        end

        def dir_exists?
          return false unless File.directory?(@base_dir)
          puts "Error: Local folder '#{@workspace_name}' already exists.".red
          true
        end

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
            when '--create-local-dir',
              @options['create_local_dir'] = true
            when '--local-only'
              @options['create_local_dir'] = true
              @options['skip_creation'] = true
            when '-c', '--credentials-file'
              @options['credentials_file'] = @args.shift
            when '-e', '--email'
              @options['email'] = @args.shift
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end
      end
    end
  end
end
