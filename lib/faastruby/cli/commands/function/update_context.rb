module FaaStRuby
  module Command
    module Function
      require 'faastruby/cli/commands/function/base_command'
      require 'faastruby/cli/new_credentials'
      class UpdateContext < FunctionBaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          load_yaml
          @function_name = @yaml_config['name']
          parse_options(require_options: {'data' => 'context data'} )
          load_credentials
        end

        def run
          spinner = spin("Uploading context data for function '#{@function_name}' to workspace '#{@workspace_name}'...")
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          function = FaaStRuby::Function.new(name: @function_name, workspace: workspace)
          function.update(new_context: @options['data'])
          if function.errors.any?
            spinner.stop('Failed :(')
            FaaStRuby::CLI.error(function.errors)
          end
          spinner.stop('Done!')
        end

        def self.help
          "update-context WORKSPACE_NAME [ARGS]"
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
-d, --data 'STRING'    # The context data. Must be quoted.
--stdin                # Read context data from STDIN
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

        def parse_options(require_options: {})
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-d', '--data'
              @options['data'] = @args.shift
            when '--stdin'
              @options['data'] = STDIN.read
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
          require_options.keys.each do |option|
            FaaStRuby::CLI.error(["Missing #{require_options[option]}".red, usage], color: nil) unless @options[option]
          end
        end
      end
    end
  end
end
