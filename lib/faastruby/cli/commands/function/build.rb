module FaaStRuby
  module Command
    module Function
      require 'faastruby/cli/commands/function/base_command'
      require 'faastruby/cli/package'
      class Build < FunctionBaseCommand
        def self.build(source, output_file, function_name, quiet = false)
          # msg = "[#{function_name}] Building package..."
          # quiet ? puts(msg) : spinner = spin(msg)
          FaaStRuby::Package.new(source, output_file).build
          # quiet ? puts("[#{function_name}] Package created.") : spinner.stop('Done!')
          puts "+ f #{output_file}".green unless quiet
        end

        def initialize(args)
          @args = args
          load_yaml
          @yaml_config['before_build'] ||= []
          @function_name = @yaml_config['name']
          @abort_when_tests_fail = @yaml_config['abort_build_when_tests_fail']
          parse_options
          @options['source'] ||= '.'
          @package_file = Tempfile.new('package')
          @options['output_file'] ||= @package_file.path
        end

        def ruby_runtime?
          @yaml_config['runtime'].nil? || @yaml_config['runtime'].match(/^ruby/)
        end

        def crystal_runtime?
          @yaml_config['runtime'].match(/^crystal/)
        end

        def run
          if ruby_runtime?
            FaaStRuby::CLI.error('Please fix the problems above and try again') unless bundle_install
          end
          if crystal_runtime?
            FaaStRuby::CLI.error('Please fix the problems above and try again') unless shards_install
          end
          tests_passed = run_tests
          FaaStRuby::CLI.error("Build aborted because tests failed and you have 'abort_build_when_tests_fail: true' in 'faastruby.yml'") unless tests_passed || !@abort_when_tests_fail
          puts "[#{@function_name}] Warning: Ignoring failed tests because you have 'abort_build_when_tests_fail: false' in 'faastruby.yml'".yellow if !tests_passed && !@abort_when_tests_fail
          build(@options['source'], @options['output_file'])
          @package_file.close
          @package_file.unlink
        end

        def self.help
          "build".light_cyan + " [-s, --source SOURCE_DIR] [-o, --output-file OUTPUT_FILE]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def build(source, output_file)
          spinner = spin("[#{@function_name}] Running 'before_build' tasks...")
          @yaml_config['before_build']&.each do |command|
            puts `#{command}`
          end
          spinner.stop(' Done!')
          self.class.build(source, output_file, @function_name)
        end

        def shards_install
          return true unless File.file?('shard.yml')
          puts "[#{@function_name}] [build] Verifying dependencies"
          system('shards check') || system('shards install')
        end

        def bundle_install
          return true unless File.file?('Gemfile')
          puts "[#{@function_name}] [build] Verifying dependencies"
          system('bundle check') || system('bundle install')
        end

        def run_tests
          require 'faastruby/cli/commands/function/test'
          FaaStRuby::Command::Function::Test.new(true).run(do_not_exit: true)
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-s', '--source-dir'
              @options['source'] = @args.shift
            when '-o', '--output-file'
              @options['output_file'] = @args.shift
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end
