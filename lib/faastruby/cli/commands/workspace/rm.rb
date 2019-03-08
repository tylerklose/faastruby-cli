module FaaStRuby
  module Command
    module Workspace
      # require 'faastruby/cli/commands/workspace/base_command'
      require 'faastruby/cli/new_credentials'
      class RM < BaseCommand
        def initialize(args)
          @args = args
          help
          @workspace_name, @relative_path = @args.shift.split(':')
          validate_command
          # FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          load_credentials
        end

        def run
          # destination_url = "#{FaaStRuby.workspace_host_for(@workspace_name)}/#{@relative_path}"
          spinner = say("[#{@relative_path}] Removing file from cloud workspace '#{@workspace_name}'...")
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          workspace.delete_file(relative_path: @relative_path)
          FaaStRuby::CLI.error(workspace.errors) if workspace.errors.any?
          spinner.stop("Done!")
          puts "* [#{@relative_path}] File removed from cloud workspace '#{@workspace_name}'.".green
        end


        def self.help
          "rm WORKSPACE_NAME:/DESTINATION/PATH"
        end

        def usage
          puts "\n# Remove static file from cloud workspace path '/DESTINATION/PATH'."
          puts "\nUsage: faastruby #{self.class.help}\n\n"
        end

        private

        def validate_command
          validate_workspace_name
          validate_relative_path
        end

        def validate_relative_path
          @relative_path.sub!(/^\//, '')
          FaaStRuby::CLI.error(["Invalid path: #{@relative_path}".red, "The path must have at least one character and can only contain letters, numbers, -, _, . and /."], color: nil) unless @relative_path&.match(/#{FUNCTION_NAME_REGEX}/)
          true
        end

        def validate_workspace_name
          FaaStRuby::CLI.error(["Invalid workspace name: #{@workspace_name}".red, "The workspace name must have between 3 and 15 characters, and can only have letters, numbers and dashes."], color: nil) unless @workspace_name&.match(/#{WORKSPACE_NAME_REGEX}/)
          true
        end


        # def missing_args
        #   FaaStRuby::CLI.error(["'#{@workspace_name}' is not a valid workspace name.".red, usage], color: nil) if @workspace_name =~ /^-.*/
        #   @missing_args << "Missing argument: WORKSPACE_NAME".red unless @workspace_name
        #   @missing_args << "Missing argument: -s SOURCE_FILE" unless @options['source']
        #   @missing_args << "Missing argument: -d DESTINATION_PATH" unless @options['destination']
        #   @missing_args << usage if @missing_args.any?
        #   @missing_args
        # end

        # def parse_options(require_options: {})
        #   @options = {}
        #   while @args.any?
        #     option = @args.shift
        #     case option
        #     when '-s', '--source'
        #       @options['source'] = @args.shift
        #     when '-d', '--destination'
        #       @options['destination'] = @args.shift.gsub(/(^\/|\/$|\.\.|;|'|"|&|\\)/, '')
        #     else
        #       FaaStRuby::CLI.error("Unknown argument: #{option}")
        #     end
        #   end
        # end
      end
    end
  end
end
