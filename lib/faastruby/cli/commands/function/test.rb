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
            puts "[skipped] You have no 'test_command' key/value in 'faastruby.yml'. Please consider using rspec!".yellow
            return true
          end
          spinner = spin("Running tests...")
          output, status = Open3.capture2e(@test_command)
          if status == 0
            spinner.stop('Passed!')
            puts output
            return true
          else
            spinner.stop('Failed :(')
            FaaStRuby::CLI.error(output, color: nil) unless do_not_exit
            puts output if do_not_exit
            return false
          end
        end

        def self.help
          'test'.blue
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end
      end
    end
  end
end
