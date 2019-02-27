module FaaStRuby
  module Sentinel
    require 'faastruby/server/sentinel/crystal_builder'
    class FunctionHandler < Sentinel::BaseHandler
      def initialize(full_path, relative_path, listener)
        @functions_dir = FaaStRuby::ProjectConfig.functions_dir(absolute: false)
        @relative_path = relative_path
        @short_path = "#{@functions_dir}/#{@relative_path}"
        @full_path = full_path
        @file_name = File.basename(@full_path)
        @listener = listener
      end

      def get_function_name_for_path(relative_path)
        function_name = File.dirname(relative_path)
        return function_name if File.file?("#{function_name}/faastruby.yml")
        get_function_name_for_path(relative_path)
      end

      def added
        return function_created!('ruby') if @file_name.match(/^handler\.rb$/)
        return function_created!('crystal') if @file_name.match(/^handler\.rb$/)
        return file_created! unless @file_name == 'faastruby.yml'
      end

      def removed
        log "File removed: #{@relative_path}"
      end

      def modified
        return file_created!
      end

      def file_created!
        log "File created: #{@relative_path}"
      end

      def function_created!(language)
        case language
        when 'ruby'
          ruby_function_created!
        when 'crystal'
          crystal_function_created!
        end
      end

      def ruby_function_created!
        file_name = File.basename(@relative_path)
        return true if file_name == 'faastruby.yml'
        function_name = File.dirname(@relative_path)
        function_folder = File.dirname(@full_path)
        @listener.stop
        add_configuration_to_folder(function_name, function_folder, runtime: DEFAULT_RUBY_RUNTIME)
        write_handler_template(@short_path, language: 'ruby')
        @listener.start
      end

      def add_configuration_to_folder(function_name, function_folder, runtime:)
        if File.file?("#{function_folder}/faastruby.yml")
          merge_faastruby_yml(function_name, function_folder, runtime: DEFAULT_RUBY_RUNTIME)
        else
          write_faastruby_yml(function_name, function_folder, runtime: DEFAULT_RUBY_RUNTIME)
        end
      end

      def merge_faastruby_yml(function_name, function_folder, runtime:)
        yaml = YAML.load(File.read("#{function_folder}/faastruby.yml"))
        write_yaml(function_name, function_folder, runtime: runtime, original: yaml)
      end

      def write_faastruby_yml(function_name, function_folder, runtime:, original: nil)
        hash = {
          'cli_version' => FaaStRuby::VERSION,
          'name' => function_name,
          'runtime' => runtime
        }
        hash = original.merge(hash) if original
        File.write("#{function_folder}/faastruby.yml", hash.to_yaml)
        unless original
          File.open("#{function_folder}/faastruby.yml", 'a') do |f|
            f.write yaml_comments
          end
        end
        log "File created: '#{function_name}/faastruby.yml'"
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

      def write_handler_template(handler_file_path, language:)
        # sleep 0.2
        content = "def handler(event)\n  # Write code here\n  \nend" if language == 'ruby'
        content = "def handler(event : FaaStRuby::Event) : FaaStRuby::Response\n  # Write code here\n  \nend" if language == 'crystal'
        File.write(handler_file_path, content)
      end
    end
  end
end