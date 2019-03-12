module FaaStRuby
  module Command
    module Project
      require 'faastruby/cli/commands/project/base_command'
      require 'faastruby/cli/template'
      require 'faastruby/cli/commands/function/new'

      DEFAULT_FUNCTIONS = {
        'root' => "local:#{FaaStRuby::Template.gem_template_path_for('web-root', runtime: 'ruby')}",
        'catch-all' => "local:#{FaaStRuby::Template.gem_template_path_for('web-404', runtime: 'ruby')}",
      }
      def self.templates_for(kind)
        t = {
          'root' => "local:#{FaaStRuby::Template.gem_template_path_for("#{kind}-root", runtime: 'ruby')}",
          'catch-all' => "local:#{FaaStRuby::Template.gem_template_path_for("#{kind}-404", runtime: 'ruby')}"
        }
        return t
      end
      class New < ProjectBaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @project_name = @args.shift
          FaaStRuby::CLI.error("The project name must have between 3 and 15 characters, and can only have letters, numbers and dashes.") unless name_valid?
          @base_dir = "./#{@project_name}"
          parse_options
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
          puts "$ faastruby local\n\n"
          puts "Then visit http://localhost:3000"
        end

        def self.help
          "new-project PROJECT_NAME [ARGS]"
        end

        def usage
          puts "Usage: faastruby #{self.class.help}"
          puts %(
--api     # Initialize a project folder using an API template
--web     # (Default) Initialize a project folder using a WEB template
          )
        end

        private

        def create_dir
          FileUtils.mkdir_p(@base_dir)
          puts "+ d #{@base_dir}".green
        end

        def git_init
          File.write("#{@base_dir}/.gitignore", "secrets.yml")
          puts "+ f #{@base_dir}/.gitignore".green
          puts `git init #{@base_dir}`
        end

        def install_functions
          current_dir = Dir.pwd
          FileUtils.mkdir_p("#{@base_dir}/functions")
          Dir.chdir("#{@base_dir}/functions")
          Project.templates_for(@options['project_type']).each do |name, template|
            args = [name, '--template', template]
            FaaStRuby::Command::Function::New.new(args).run(print_base_dir: "#{@base_dir}/functions", blank_template: true)
          end
          Dir.chdir("..")
          if @options['project_type'] == 'web'
            copy_public_template
          else
            create_public_folder
          end
          Dir.chdir(current_dir)
        end

        def create_public_folder
          Dir.mkdir 'public'
          puts "+ d #{@base_dir}/public".green
          write_public_config
        end

        def copy_public_template
          template_dir = "#{Gem::Specification.find_by_name("faastruby").gem_dir}/templates/public-#{@options['project_type']}"
          FileUtils.cp_r(template_dir, "./public")
          write_public_config
        end

        def write_public_config
          File.write("public/faastruby.yml", default_public_config)
          puts "+ f #{@base_dir}/public/faastruby.yml".green
        end

        def create_config
          File.write("#{@base_dir}/#{PROJECT_YAML_FILE}", default_project_file)
          puts "+ f #{@base_dir}/#{PROJECT_YAML_FILE}".green
          if @options['tmux']
            File.write("#{@base_dir}/tmuxinator.yml", tmuxinator_config)
            puts "+ f #{@base_dir}/tmuxinator.yml".green
          end
          File.write("#{@base_dir}/#{PROJECT_SECRETS_FILE}", default_secrets_file)
          puts "+ f #{@base_dir}/#{PROJECT_SECRETS_FILE}".green
        end

        def default_public_config
          [
            "cli_version: #{FaaStRuby::VERSION}",
            'name: public',
            'serve_static: true',
          ].join("\n")
        end

        def default_secrets_file
          [
            'secrets:',
            "  # Add secrets here and they will be available inside the function as \"event.context\"",
            "  # Example:",
            "  # prod:",
            "  #   pages/root:",
            "  #     a_secret: bfe76f4557ffc2de901cb24e0f87436f",
            "  #   another/function:",
            "  #     another_secret: 4d1c281e.619a2489c.8b5d.dd945616d324",
            "  # stage:",
            "  #   pages/root:",
            "  #     a_secret: bfe76f4557ffc2de901cb24e0f87436f",
            "  #   another/function:",
            "  #     another_secret: 4d1c281e.619a2489c.8b5d.dd945616d324"
          ].join("\n")
        end

        def default_project_file
          [
            "project:",
            "  # The project name",
            "  name: #{@project_name}",
            "  # The project identifier is used to ensure your workspaces will have unique names.",
            "  # This is not a secret, but don't lose it!",
            "  identifier: #{Digest::MD5.hexdigest(Time.now.to_s).slice(0..5)}",
            "",
            "  ## The 'public' directory, where you put static files.",
            "  ## Files will be served from here first, meaning that if",
            "  ## you have a function at '/product' and a folder '/product'",
            "  ## inside the public folder, the public one will take precedence.",
            "  ## Defaults to 'public'.",
            "  # public_dir: public",
            "",
            "  ## The name of the folder containing your functions. Defaults to 'functions'",
            "  # functions_dir: functions",
            "",
            "  ## The name of the function that will respond to requests made",
            "  ## to '/'. Defaults to 'root'",
            "  # root_to: root",
            "",
            "  ## The setting 'catch_all' allows you to capture requests to",
            "  ## non-existing functions and send them to another function.",
            "  ## This is useful for setting custom 404 pages, for example.",
            "  ## Defaults to 'catch-all'.",
            "  # catch_all: catch-all"
          ].join("\n")
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
            when '--tmux'
              @options['tmux'] = true
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
