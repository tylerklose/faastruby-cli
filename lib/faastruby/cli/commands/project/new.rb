module FaaStRuby
  module Command
    module Project
      DEFAULT_FUNCTIONS = {
        'root' => "local:#{FaaStRuby::Template.gem_template_path_for('web-root', runtime: 'ruby')}",
        'error_pages/404' => "local:#{FaaStRuby::Template.gem_template_path_for('web-404', runtime: 'ruby')}",
        'assets/styles' => "local:#{FaaStRuby::Template.gem_template_path_for('web-css', runtime: 'ruby')}",
        'assets/js' => "local:#{FaaStRuby::Template.gem_template_path_for('web-js', runtime: 'ruby')}"
      }
      def self.templates_for(kind)
        t = {
          'root' => "local:#{FaaStRuby::Template.gem_template_path_for("#{kind}-root", runtime: 'ruby')}",
          'error_pages/404' => "local:#{FaaStRuby::Template.gem_template_path_for("#{kind}-404", runtime: 'ruby')}"
        }
        case kind
        when 'web'
          t['assets/styles'] = "local:#{FaaStRuby::Template.gem_template_path_for("#{kind}-css", runtime: 'ruby')}"
          t['assets/js'] = "local:#{FaaStRuby::Template.gem_template_path_for("#{kind}-js", runtime: 'ruby')}"
        end
        return t
      end
      class New < ProjectBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @project_name = @args.shift
          FaaStRuby::CLI.error("The project name must have between 3 and 15 characters, and can only have letters, numbers and dashes.") unless name_valid?
          @base_dir = "./#{@project_name}"
          parse_options
          @options['credentials_file'] ||= PROJECT_CREDENTIALS_FILE
          @options['project_type'] ||= 'web'
        end

        def run
          dir_exists?
          create_dir
          create_config
          install_functions
          git_init
          puts "Project '#{@project_name}' initialized."
          puts "Now run:"
          puts "$ cd #{@project_name}"
          puts "$ faastruby server\n\n"
          puts "Then visit http://localhost:3000"
        end

        def self.help
          "new-project".light_cyan + " PROJECT_NAME"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def create_dir
          FileUtils.mkdir_p(@base_dir)
          puts "+ d #{@base_dir}".green
        end

        def git_init
          File.write("#{@base_dir}/.gitignore", ".credentials.yml")
          puts "+ f #{@base_dir}/.gitignore".green
          puts `git init #{@base_dir}`
        end

        def install_functions
          current_dir = Dir.pwd
          Dir.chdir(@base_dir)
          Project.templates_for(@options['project_type']).each do |name, template|
            args = [name, '--template', template]
            FaaStRuby::Command::Function::New.new(args).run(print_base_dir: @base_dir, blank_template: true)
          end
          Dir.chdir(current_dir)
        end
        
        def create_config
          File.write("#{@base_dir}/#{PROJECT_YAML_FILE}", default_project_file)
          puts "+ f #{@base_dir}/#{PROJECT_YAML_FILE}".green
          File.write("#{@base_dir}/tmuxinator.yml", tmuxinator_config)
          puts "+ f #{@base_dir}/tmuxinator.yml".green
        end

        def default_project_file
          {
            'name' => @project_name,
            'environments' => ['prod', 'stage'],
            'root_to' => 'root',
            '404_to' => 'error_pages/404'
          }.to_yaml
        end

        def tmuxinator_config
          {
            "name" => @project_name,
            "root" => ".",
            "startup_window" => "server",
            "windows" => [{
              "server" => {
                "layout" => "main-horizontal",
                  "panes" => [
                    [
                      "tmux set -g mouse on",
                      "tmux set -g history-limit 30000",
                      "clear",
                      "faastruby server"
                    ],
                    [
                      "tmux select-pane -t 0.1",
                      "clear"
                    ]
                  ]
                }
              }
            ]
          }.to_yaml
        end

        def dir_exists?
          return false unless File.directory?(@base_dir)
          FaaStRuby::CLI.error("Error: Directory '#{@project_name}' already exists. Aborting.")
        end

        def name_valid?
          return true if @project_name.match(/^#{WORKSPACE_NAME_REGEX}$/)
          return false
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: PROJECT_NAME".red
            @missing_args << usage
          end
          FaaStRuby::CLI.error(["'#{@args.first}' is not a valid project name.".red, usage], color: nil) if @args.first =~ /^-.*/
          @missing_args
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '--web', '-w'
              @options['project_type'] = 'web'
            when '--api', '-a'
              @options['project_type'] = 'api'
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end
      end
    end
  end
end
