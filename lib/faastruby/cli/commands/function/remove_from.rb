module FaaStRuby
  module Command
    module Function
      require 'faastruby/cli/commands/function/base_command'
      require 'faastruby/cli/new_credentials'
      class RemoveFrom < FunctionBaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          parse_options
          load_yaml
          @function_name = @options['function_name'] || @yaml_config['name']
          load_credentials
        end

        def load_yaml
          return true if @options['function_name']
          super
        end

        def run
          warning unless @options['force']
          FaaStRuby::CLI.error("Cancelled") unless @options['force'] == 'y'
          spinner = spin("Removing function '#{@function_name}' from workspace '#{@workspace_name}'...")
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          function = FaaStRuby::Function.new(name: @function_name, workspace: workspace)
          function.destroy
          if function.errors.any?
            spinner.stop('Failed :(')
            FaaStRuby::CLI.error(function.errors)
          end
          spinner.stop('Done!')
        end

        def self.help
          "remove-from WORKSPACE_NAME [ARGS]"
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
-y,--yes                       # Don't prompt for confirmation
-f,--function FUNCTION_NAME    # Pass the function name instead of attempting
                               # to read from the function's config file.
          )
        end

        private

        def warning
          print "WARNING: ".red
          puts "This action will permanently remove the function '#{@function_name}' from the workspace '#{@workspace_name}'."
          print "Are you sure? [y/N] "
          @options['force'] = STDIN.gets.chomp
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-y', '--yes'
              @options['force'] = 'y'
            when '--function', '-f'
              @options['function_name'] = @args.shift
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: WORKSPACE_NAME".red
            @missing_args << usage
          end
          FaaStRuby::CLI.error(["'#{@args.first}' is not a valid workspace name.".red, usage], color: nil) if @args.first =~ /^-.*/
          @missing_args
        end
      end
    end
  end
end
