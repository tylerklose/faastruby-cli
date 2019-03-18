STDOUT.sync
require 'open3'
module FaaStRuby
  module Command
    STDOUT_MUTEX = Mutex.new
    module Project
      require 'faastruby/cli/commands/project/base_command'
      require 'faastruby/server/logger'
      class Deploy < ProjectBaseCommand
        extend FaaStRuby::Logger
        def initialize(args)
          @errors = []
          @args = args
          help
          parse_options
          @mutex = Mutex.new
          @failed = {}
          @options['functions'] += find_functions unless @options['functions'].any?
          @options['environment'] ||= 'stage'
          @project_yaml = YAML.load(File.read(PROJECT_YAML_FILE))['project'] rescue FaaStRuby::CLI.error("Could not find file 'project.yml'. Are you running this command from the project's folder?")
          @project_secrets = YAML.load(File.read(PROJECT_SECRETS_FILE))['secrets'] rescue {secrets: {}}
          @project_name = @project_yaml['name']
          @root_to = @project_yaml['root_to'] || 'root'
          @catch_all = @project_yaml['catch_all'] || 'catch-all'
          @project_identifier = "-#{@project_yaml['identifier']}" if @project_yaml['identifier']
          @workspace = "#{@project_name}-#{@options['environment']}#{@project_identifier}"
          @spinners = TTY::Spinner::Multi.new("Deploying project '#{@project_name}' to workspace '#{@workspace}'", format: SPINNER_FORMAT)
          # puts
        end

        def puts(msg)
          STDOUT_MUTEX.synchronize do
            STDOUT.puts msg
          end
        end

        def run
          result = []
          errors = false
          root_folder = Dir.pwd
          jobs = []

          # spinner = spin "Deploying project '#{@project_name}' to workspace #{workspace}..."
          connect_spinner = @spinners.register "[:spinner] Connecting to workspace '#{@workspace}'"
          connect_spinner.auto_spin
          try_workspace(@workspace, connect_spinner)
          @options['functions'].each do |function_path|
            jobs << Thread.new do
              function_config = YAML.load(File.read("#{function_path}/faastruby.yml"))
              function_name = function_config['name']
              msg = function_name == 'public' ? "Uploading static assets in '#{function_name}'" : "Deploying function '#{function_path}'"
              spinner = @spinners.register "[:spinner] #{msg}"
              spinner.auto_spin
              # puts "[#{function_path}] Entering folder '#{function_path}'"
              # Dir.chdir function_path
              cmd = "cd #{function_path} && faastruby deploy-to #{@workspace} --quiet --dont-create-workspace"
              cmd += " --set-root" if @root_to == function_name
              cmd += " --set-catch-all" if @catch_all == function_name
              secrets = secrets_for(function_name)
              secrets_json = Oj.dump(secrets) if secrets
              cmd += " --context '#{secrets_json}'" if secrets_json
              output, status = Open3.capture2e(cmd)
              if status == 0
                spinner.success
              else
                add_failed(function_name, output)
                spinner.error
              end
            end
          end
          jobs.each{|thr| thr.join}
          if @failed.any?
            puts "\n\nFAILURES:".red
            @failed.each do |function_name, output|
              puts "* Function '#{function_name}' deploy failed:".red
              puts output
              puts nil
            end
          else
            puts "* Project URL: #{FaaStRuby.workspace_host_for(@workspace)}\n".green
          end
        end

        def secrets_for(function_name)
          secrets = @project_secrets[@options['environment']]
          return nil unless secrets
          secrets[function_name]
        end

        def add_failed(function_name, output)
          @mutex.synchronize do
            @failed[function_name] = output
          end
        end

        def try_workspace(workspace, connect_spinner)
          return true if @options['skip_create_workspace']
          try_to_create = Proc.new {system("faastruby create-workspace #{workspace} > /dev/null 2>&1")}
          has_credentials = system("faastruby list-workspace #{workspace} > /dev/null 2>&1")
          continue = has_credentials || try_to_create.call
          unless continue
            connect_spinner.error
            FaaStRuby::CLI.error("Unable to deploy project to workspace '#{workspace}'. Make sure you have the credentials, or try a different environment name.\nExample: faastruby deploy --deploy-env #{@options['environment']}-#{(rand * 100).to_i}")
          end
          connect_spinner.success
          true
        end

        def find_functions
          Dir.glob("**/faastruby.yml").map do |f|
            path = f.split('/')
            path.pop
            path.join('/')
          end
        end

        def self.help
          "deploy [ARGS]"
        end

        def usage
          puts "Usage: faastruby #{self.class.help}"
          puts %(
-f,--function FUNCTION_PATH    # Specify the path to the function directory in your local machine.
                               # This argument can be repeated many times for multiple functions. Example:
                               # -f path/to/function1 -f path/to/function2
-e,--env ENVIRONMENT           # ENVIRONMENT is added to the project's name to compose the workspace name.
          )
        end

        def parse_options
          @options = {'functions' => []}
          while @args.any?
            option = @args.shift
            case option
            when '--skip-create-workspace'
              @options['skip_create_workspace'] = true
            when '--function', '-f'
              @options['functions'] << @args.shift
            when '--env', '-e'
              @options['environment'] = @args.shift
            else
              FaaStRuby::CLI.error("Unknown argument: #{option}")
            end
          end
        end

      end
    end
  end
end
