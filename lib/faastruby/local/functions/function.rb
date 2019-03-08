module FaaStRuby
  module Local
    class MissingConfigurationFileError < StandardError;end
    class Function
      include Local::Logger
      extend Local::Logger
      def self.find_all_in(functions_dir)
        debug "self.find_all_in(#{functions_dir.inspect})"
        Dir.glob(["**/handler.rb", "**/handler.cr"], base: functions_dir).map do |entry|
          function_absolute_folder = "#{functions_dir}/#{File.dirname(entry)}"
          next unless File.file?("#{function_absolute_folder}/faastruby.yml")
          from_yaml(function_absolute_folder)
        end.compact
      end

      def self.that_has_file(entry, event_type)
        debug "self.that_has_file(#{entry.inspect})"
        absolute_folder = get_function_folder_for(entry)
        if event_type == :removed
          name = absolute_folder.dup
          name.slice!("#{Local.functions_dir}/")
          return new(
            name: name,
            before_build: [],
            absolute_folder: absolute_folder
          )
        end
        from_yaml(absolute_folder)
      end

      def self.from_yaml(absolute_folder)
        debug "self.from_yaml(#{absolute_folder.inspect})"
        yaml_file = "#{absolute_folder}/faastruby.yml"
        yaml = YAML.load(File.read(yaml_file))
        language, runtime_version = yaml['runtime'].split(':')
        object = Local::RubyFunction if language == 'ruby'
        object = Local::CrystalFunction if language == 'crystal'
        object.new(
          name: yaml['name'],
          before_build: yaml['before_build'],
          absolute_folder: absolute_folder
        )
      end

      def self.get_function_folder_for(entry)
        return File.dirname(entry) if File.basename(entry) == 'faastruby.yml'
        debug "self.get_function_folder_for(#{entry.inspect})"
        dirname = File.dirname(entry)
        raise MissingConfigurationFileError.new("ERROR: Could not determine which function the file belongs to. Make sure your functions have the configuration file 'faastruby.yml'.") if dirname == SERVER_ROOT
        return dirname if File.file?("#{dirname}/faastruby.yml")
        get_function_folder_for(dirname)
      end

      #### Instance methods
      attr_accessor :name, :before_build, :absolute_folder
      def initialize(name:, before_build: [], absolute_folder:)
        debug "initialize(name: #{name.inspect}, before_build: #{before_build.inspect}, absolute_folder: #{absolute_folder.inspect})"
        @name = name
        @before_build = before_build || []
        @absolute_folder = absolute_folder
      end

      def deploy
        debug "deploy"
        deploy_cmd, deploy_cmd_print = generate_deploy_command
        puts "Running: #{deploy_cmd_print.join(' ')}"
        output, status = Open3.capture2e(deploy_cmd.join(' '))
        STDOUT.puts "#{Time.now} | " + "* [#{name}] Deploying...".green
        STDOUT.puts "---"
        String.disable_colorization = true
        if status.exitstatus == 0
          output.split("\n").each {|o| puts o unless o == '---'}
        else
          puts "* [#{name}] Deploy Failed:"
          STDERR.puts output
        end
        String.disable_colorization = false
      end

      def language
        case YAML.load(File.read("#{@absolute_folder}/faastruby.yml"))['runtime']
        when /^ruby:/
          "ruby"
        when /^crystal:/
          "crystal"
        end
      end

      def generate_deploy_command
        debug "generate_deploy_command"
        project_config = Local.project_config
        deploy_cmd = ['faastruby', 'deploy-to', Local.workspace, '-f', @absolute_folder, '--dont-create-workspace']
        deploy_cmd << '--set-root' if Local.root_to == @name
        deploy_cmd << '--set-catch-all' if Local.catch_all == @name
        secrets_json = Oj.dump(Local.secrets_for_function(@name)) rescue nil
        deploy_cmd_print = deploy_cmd
        if secrets_json
          deploy_cmd += ["--context", secrets_json]
          deploy_cmd_print += ["--context", '*REDACTED*']
        end
        [deploy_cmd, deploy_cmd_print]
      end

      def compile
        debug "compile"
        true
      end

      def remove_from_workspace
        debug "remove_from_workspace"
        remove_cmd = ["faastruby", "remove-from", Local.workspace, "-y", "-f", @name]
        puts "Removing function '#{@name}' from the cloud workspace '#{Local.workspace}'."
        removed = system(*remove_cmd)
        STDOUT.puts '---'
        if removed
          puts "Function '#{@name}' was removed from the cloud workspace '#{Local.workspace}'."
        end
      end

      def initialize_new_function
        debug "initialize_new_function"
        write_yaml
        write_handler
      end

      def merge_yaml(hash, yaml_file)
        debug "merge_yaml(#{hash.inspect}, #{yaml_file.inspect})"
        new_config = load_yaml.merge(hash)
        File.write(yaml_file, new_config.to_yaml)
      end

      def load_yaml
        debug "load_yaml"
        YAML.load(File.read("#{@absolute_folder}/faastruby.yml"))
      end

      def write_yaml
        debug "write_yaml"
        yaml_file = "#{@absolute_folder}/faastruby.yml"
        if File.file?(yaml_file)
          merge_yaml(yaml_hash, yaml_file)
        else
          File.write(yaml_file, yaml_hash.to_yaml)
        end
        File.open(yaml_file, 'a') do |f|
          f.write yaml_comments
        end
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
          '## To schedule periodic runs, follow the example below:',
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
    end
  end
end