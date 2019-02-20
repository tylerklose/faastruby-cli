require 'open3'
module FaaStRuby
  module Command
    module Function
      class Test < FunctionBaseCommand
        def initialize(args)
          @args = args
          load_yaml
          @function_name = @yaml_config['name']
          @test_command = @yaml_config['test_command']
        end

        def run(do_not_exit: false)
          unless @test_command
            # puts "[skipped tests] You have no 'test_command' key/value in 'faastruby.yml'. Please consider using rspec!".yellow
            return true
          end
          # puts "[test] Running tests"
          system(@test_command)
        end

        def self.help
          'test'.light_cyan
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end
      end
    end
  end
end
