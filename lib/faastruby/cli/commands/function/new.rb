module FaaStRuby
  module Command
    module Function
      class New < FunctionBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @function_name = @args.shift
          @base_dir = "./#{@function_name}"
          @yaml_content = {
            'name' => @function_name,
            'test_command' => 'rspec',
            'abort_build_when_tests_fail' => true,
            'abort_deploy_when_tests_fail' => true
          }
          parse_options
          @options['template'] ||= 'example'
        end

        def run
          dir_exists? unless @options['force']
          copy_template
          write_yaml
          bundle_install
        end

        def self.help
          "new".blue + " FUNCTION_NAME [--blank] [--force]" +
          <<-EOS

    --blank              # Create a blank function
    --force              # Continue if directory already exists and overwrite files
EOS
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-f', '--force'
              @options['force'] = true
            when '--blank'
              @options['template'] = 'example-blank'
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def dir_exists?
          return unless File.directory?(@base_dir)
          print "The directory '#{@function_name}' already exists. Overwrite files? [y/N] "
          response = STDIN.gets.chomp
          FaaStRuby::CLI.error("Cancelled", color: nil) unless response == 'y'
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: FUNCTION_NAME".red
            @missing_args << usage
          end
          @missing_args
        end

        def copy_template
          source = "#{Gem::Specification.find_by_name("faastruby").gem_dir}/#{@options['template']}"
          FileUtils.mkdir_p(@base_dir)
          FileUtils.cp_r("#{source}/.", "#{@base_dir}/")
          puts "+ d #{@base_dir}".green
          puts "+ d #{@base_dir}/spec".green
          puts "+ d #{@base_dir}/spec/helpers".green
          puts "+ f #{@base_dir}/spec/helpers/faastruby.rb".green
          puts "+ f #{@base_dir}/spec/handler_spec.rb".green
          puts "+ f #{@base_dir}/spec/spec_helper.rb".green
          puts "+ f #{@base_dir}/Gemfile".green
          puts "+ f #{@base_dir}/handler.rb".green
        end

        def write_yaml
          write_file("#{@base_dir}/faastruby.yml", @yaml_content.to_yaml)
        end

        def bundle_install
          spinner = spin("Installing gems...")
          system("bundle install --gemfile=#{@base_dir}/Gemfile > /dev/null")
          spinner.stop('Done!')
        end
      end
    end
  end
end