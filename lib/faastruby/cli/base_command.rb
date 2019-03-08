require 'tty-spinner'
require 'yaml'
module FaaStRuby
  module Command
    class BaseCommand
      def self.spin(message)
        spinner = TTY::Spinner.new(":spinner #{message}", format: SPINNER_FORMAT)
        spinner.auto_spin
        spinner
      end

      def write_file(path, content, mode = 'w', print_base_dir: false, extra_content: nil)
        base_dir = print_base_dir ? "#{print_base_dir}/" : ""
        File.open(path, mode) do |f|
          f.write(content)
          f.write(extra_content) if extra_content
        end
        message = "#{mode == 'w' ? '+' : '~'} f #{base_dir}#{path}"
        puts message.green if mode == 'w'
        puts message.yellow if mode == 'w+' || mode == 'a'
      end

      def say(message, quiet: false)
        return puts "\n#{message}" if quiet
        spin(message)
      end

      def load_credentials
        @credentials_file = NewCredentials::CredentialsFile.new
        @credentials = @credentials_file.get
        FaaStRuby.configure do |config|
          config.api_key = @credentials['api_key']
          config.api_secret = @credentials['api_secret']
        end
      end

      def help
        if ['-h', '--help'].include?(@args.first)
          usage
          exit 0
        end
      end

      def has_user_logged_in?
        NewCredentials::CredentialsFile.new.has_user_logged_in?
      end

      def spin(message)
        spinner = TTY::Spinner.new(":spinner #{message}", format: SPINNER_FORMAT)
        spinner.auto_spin
        spinner
      end

      def load_yaml
        if File.file?(FAASTRUBY_YAML)
          return YAML.load(File.read(FAASTRUBY_YAML))
        end
        FaaStRuby::CLI.error("Could not find file #{FAASTRUBY_YAML}")
      end

      def spin(message)
        self.class.spin(message)
      end
    end
  end
end
