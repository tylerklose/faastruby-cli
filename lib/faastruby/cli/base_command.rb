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

      def write_file(path, content, mode = 'w', print_base_dir: false)
        base_dir = print_base_dir ? "#{print_base_dir}/" : ""
        File.open(path, mode){|f| f.write(content)}
        message = "#{mode == 'w' ? '+' : '~'} f #{base_dir}#{path}"
        puts message.green if mode == 'w'
        puts message.yellow if mode == 'w+' || mode == 'a'
      end

      def say(message, quiet: false)
        return puts message if quiet
        spin(message)
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
