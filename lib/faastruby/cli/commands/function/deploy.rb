module FaaStRuby
  module Command
    module Function
      class Deploy < FunctionBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          load_yaml
          @function_name = @yaml_config['name']
          @abort_when_tests_fail = @yaml_config['abort_deploy_when_tests_fail']
          FaaStRuby::Credentials.load_for(@workspace_name)
        end

        def run
          tests_passed = run_tests
          FaaStRuby::CLI.error("Deploy aborted because tests failed and you have 'abort_deploy_when_tests_fail: true' in 'faastruby.yml'") unless tests_passed || !@abort_when_tests_fail
          puts "Warning: Ignoring failed tests because you have 'abort_deploy_when_tests_fail: false' in 'faastruby.yml'".yellow if !tests_passed && !@abort_when_tests_fail
          package_file_name = build_package
          spinner = spin("Deploying to workspace '#{@workspace_name}'...")
          workspace = FaaStRuby::Workspace.new(name: @workspace_name).deploy(package_file_name)
          if workspace.errors.any?
            spinner.stop('Failed :(')
            FaaStRuby::CLI.error(workspace.errors)
          end
          spinner.stop('Done!')
        end

        def self.help
          "deploy-to".blue + " WORKSPACE_NAME"
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

        def run_tests
          FaaStRuby::Command::Function::Test.new(true).run(do_not_exit: true)
        end

        def build_package
          source = '.'
          output_file = "#{@function_name}.zip"
          FaaStRuby::Command::Function::Build.build(source, output_file, true)
          output_file
        end
      end
    end
  end
end
