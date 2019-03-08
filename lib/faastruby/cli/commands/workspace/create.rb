module FaaStRuby
  module Command
    module Workspace
      # require 'faastruby/cli/commands/workspace/base_command'
      require 'faastruby/cli/new_credentials'
      class Create < BaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          validate_name
          @base_dir = "./#{@workspace_name}"
          parse_options
          load_credentials
        end

        def run(create_directory: true, exit_on_error: true)
          unless @options['skip_creation']
            spinner = spin("Setting up workspace '#{@workspace_name}'...")
            workspace = FaaStRuby::Workspace.create(name: @workspace_name, email: @options['email'])
            if workspace.errors.any?
              spinner.stop(" Failed :(") if exit_on_error
              FaaStRuby::CLI.error(workspace.errors) if exit_on_error
              spinner.stop
              return false
            end
            spinner.stop(" Done!")
          end
          create_dir if @options['create_local_dir'] && create_directory && !dir_exists?
          true
        end

        def self.help
          "create-workspace WORKSPACE_NAME [ARGS]"
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
--create-local-dir    # Create a local folder in addition to the cloud
--local-only          # Only create a local folder. Skip creating workspace on the cloud
          )
        end

        private

        def create_dir
          FileUtils.mkdir_p(@base_dir)
          puts "+ d #{@base_dir}".green
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

        def validate_name
          unless @workspace_name.match(/^#{WORKSPACE_NAME_REGEX}$/)
            FaaStRuby::CLI.error("The workspace name must have between 3 and 15 characters, and can only have letters, numbers and dashes.")
          end
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '--create-local-dir',
              @options['create_local_dir'] = true
            when '--local-only'
              @options['create_local_dir'] = true
              @options['skip_creation'] = true
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end
      end
    end
  end
end
