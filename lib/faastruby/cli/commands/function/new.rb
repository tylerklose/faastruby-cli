require 'erb'
module FaaStRuby
  require 'faastruby/version'
  module Command
    module Function
      require 'faastruby/supported_runtimes'
      require 'faastruby/cli/commands/function/base_command'
      require 'faastruby/cli/template'
      class New < FunctionBaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @function_name = @args.shift
          FaaStRuby::CLI.error("The function name must have at least one character and can only contain letters, numbers, -, _, . and /. Names with just a period are not allowed. Invalid name: #{@function_name}") unless name_valid?
          parse_options
          @base_dir ||= @function_name
          @options['runtime_name'] ||= 'ruby'
          @options['runtime_version'] ||= '2.5.3'
          if @options['blank_template']
            @options['template'] = FaaStRuby::Template.new(type: 'local', source: Template.gem_template_path_for('example-blank', runtime: @options['runtime_name'] || 'ruby'))
          else
            @options['template'] ||= FaaStRuby::Template.new(type: 'local', source: Template.gem_template_path_for('example', runtime: @options['runtime_name']))
          end
        end

        def run(print_base_dir: false, blank_template: false)
          @options['blank_template'] ||= blank_template
          @options['template'].install(to: @base_dir, force: @options['force'], print_base_dir: print_base_dir)
          faastruby_yaml = "#{@base_dir}/faastruby.yml"
          if File.file?(faastruby_yaml)
            @yaml_content = YAML.load(File.read(faastruby_yaml))
            @yaml_content['name'] = @function_name
            @options['runtime_name'], @options['runtime_version'] = @yaml_content['runtime']&.split(':')
            @options['runtime_name'] ||= 'ruby'
            @options['runtime_version'] ||= '2.5.3'
          else
            @yaml_content = yaml_for(@options['runtime_name'])
          end
          write_yaml(print_base_dir: print_base_dir)
          post_tasks(@options['runtime_name'])
        end

        def self.help
          "new FUNCTION_NAME [ARGS]"
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
--blank          # Create a blank function
--force          # Continue if directory already exists and overwrite files
-g, --git        # Initialize a Git repository.
--runtime        # Set the language runtime.
                 # Options are: #{SUPPORTED_RUNTIMES.join(', ')}
--template TYPE(local|git|github):SOURCE   # Initialize the function using a template
                                           # Examples:
                                           # --template local:/path/to/folder
                                           # --template git:git@github.com:user/repo.git
                                           # --template github:user/repo
)
        end

        private

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-g', '--git'
              @options['git_init'] = true
            when '--template'
              FaaStRuby::CLI.error("Option '--template' can't be used with '--blank' or '--runtime'.".red) if @options['runtime'] || @options['blank_template']
              template = @args.shift
              type, *source = template.split(':')
              source = source.join(':')
              @options['template'] = FaaStRuby::Template.new(type: type, source: source)
            when '--runtime'
              FaaStRuby::CLI.error("Option '--runtime' can't be used with '--template' or '--blank'.".red) if @options['template']
              @options['runtime'] = @args.shift
              @options['runtime_name'], @options['runtime_version'] = @options['runtime'].split(':')
              template_name = @options['blank_template'] ? 'example-blank' : 'example'
              @options['template'] = FaaStRuby::Template.new(type: 'local', source: Template.gem_template_path_for('example', runtime: @options['runtime_name']))
              FaaStRuby::CLI.error(["Unsupported runtime: #{@options['runtime']}".red, "Supported values are #{SUPPORTED_RUNTIMES.join(", ")}"], color: nil) unless SUPPORTED_RUNTIMES.include?(@options['runtime'])
            when '-f', '--force'
              @options['force'] = true
            when '--blank'
              @options['template'] = nil
              FaaStRuby::CLI.error("Option '--blank' can't be used with '--blank' or '--template'.".red) if @options['template']
              @options['blank_template'] = true
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: FUNCTION_NAME".red
            @missing_args << usage
          end
          @missing_args
        end

        def yaml_comments
          [
            '## You can add commands to run locally before building the deployment package.',
            "## Some use cases are:",
            "## * minifying Javascript/CSS",
            "## * downloading a file to be included in the package.",
            "# before_build:",
            "#   - curl https://some.url --output some.file",
            "#   - uglifyjs your.js -c -m -o your.min.js",
            '',
            '# To schedule periodic runs, follow the example below:',
            '# schedule:',
            '#   job1:',
            '#     when: every 2 hours',
            '#     body: {"foo": "bar"}',
            '#     method: POST',
            '#     query_params: {"param": "value"}',
            '#     headers: {"Content-Type": "application/json"}',
            '#   job2: ...'
          ].join("\n")
        end

        def yaml_for(runtime_name)
          case runtime_name
          when 'crystal'
            test_command = 'crystal spec --no-color'
          when 'ruby'
            test_command = 'rspec'
          else
            test_command = 'rspec'
          end
          if @options['blank_template']
            {
              'cli_version' => FaaStRuby::VERSION,
              'name' => @function_name,
              'runtime' => @options['runtime'] || 'ruby:2.5.3'
            }
          else
            {
              'cli_version' => FaaStRuby::VERSION,
              'name' => @function_name,
              'before_build' => [],
              'runtime' => @options['runtime'] || 'ruby:2.5.3',
              'test_command' => test_command
            }
          end
        end

        def write_yaml(print_base_dir: false)
          write_file("#{@function_name}/faastruby.yml", @yaml_content.to_yaml, print_base_dir: print_base_dir, extra_content: yaml_comments)
        end

        def post_tasks(runtime_name)
          return true if @options['blank_template']
          update_readme
          puts `git init #{@base_dir}` if @options['git_init']
          case runtime_name
          when 'ruby'
            bundle_install
          when 'crystal'
            write_shards_file
            shards_install
          else
            bundle_install
          end
        end

        def update_readme
          file_path = "#{@base_dir}/README.md"
          return false unless File.file?(file_path)
          readme = File.read(file_path)
          File.write(file_path, ERB.new(readme).result(binding))
        end

        def bundle_install
          return true unless File.file?("#{@base_dir}/Gemfile")
          spinner = spin("Installing gems...")
          system("bundle install --gemfile=#{@base_dir}/Gemfile > /dev/null")
          spinner.stop('Done!')
        end

        def write_shards_file
          shards = {
            'name' => @function_name,
            'version' => '0.1.0',
            'crystal' => @options['runtime_version'],
            'targets' => {
              @function_name => {
                'main' => 'src/handler.cr'
              }
            },
            'development_dependencies' => {
              'faastruby-spec-helper' => {
                'github' => 'faastruby/faastruby-spec-helper.cr',
                'version' => '~> 0.1.0'
              }
            }
          }.to_yaml
          write_file("#{@base_dir}/shard.yml", shards)
        end

        def shards_install
          return true unless File.file?("#{@base_dir}/shard.yml")
          spinner = spin("Installing shards...")
          system("cd #{@base_dir} && shards install > /dev/null")
          spinner.stop('Done!')
        end

        def name_valid?
          return false unless @function_name.match(/^#{FUNCTION_NAME_REGEX}$/)
          while @function_name.match(/\.\./) || @function_name.match(/^\.\//) || @function_name.match(/(^\/|\/$)/)
            @function_name.gsub!('..', '.')
            @function_name.gsub!(/^\.\//, '')
            @function_name.gsub!(/(^\/|\/$)/, '')
          end
          if @function_name == '.' || @function_name == '' || @function_name.match(/\.\./)
            return false
          end
          return true
        end
      end
    end
  end
end
