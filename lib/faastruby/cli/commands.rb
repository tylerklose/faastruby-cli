module FaaStRuby
  module Command
    class BaseCommand
      def self.spin(message)
        spinner = TTY::Spinner.new(":spinner #{message}", format: SPINNER_FORMAT)
        spinner.auto_spin
        spinner
      end

      def write_file(path, content, mode = 'w')
        File.open(path, mode){|f| f.write(content) }
        message = "#{mode == 'w' ? '+' : '~'} f #{path}"
        puts message.green if mode == 'w'
        puts message.yellow if mode == 'w+' || mode == 'a'
      end

      def spin(message)
        spinner = TTY::Spinner.new(":spinner #{message}", format: SPINNER_FORMAT)
        spinner.auto_spin
        spinner
      end

      def load_yaml
        return YAML.load(File.read(FAASTRUBY_YAML)) if File.file?(FAASTRUBY_YAML)
        FaaStRuby.error("Could not find file #{FAASTRUBY_YAML}")
      end

      def spin(message)
        self.class.spin(message)
      end
    end
  end
end

require 'faastruby/cli/credentials'
require 'faastruby/cli/commands/function'
require 'faastruby/cli/commands/workspace'
require 'faastruby/cli/commands/credentials'
require 'faastruby/cli/commands/help'
require 'faastruby/cli/commands/version'

module FaaStRuby
  module Command
    COMMANDS = {
      'new' => FaaStRuby::Command::Function::New,
      'deploy-to' => FaaStRuby::Command::Function::Deploy,
      'remove-from' => FaaStRuby::Command::Function::RemoveFrom,
      'update-context' => FaaStRuby::Command::Function::UpdateContext,
      'upgrade' => FaaStRuby::Command::Function::Upgrade,
      'build' => FaaStRuby::Command::Function::Build,
      'create-workspace' => FaaStRuby::Command::Workspace::Create,
      'destroy-workspace' => FaaStRuby::Command::Workspace::Destroy,
      'list-workspace' => FaaStRuby::Command::Workspace::List,
      'test' => FaaStRuby::Command::Function::Test,
      'run' => FaaStRuby::Command::Function::Run,
      'add-credentials' => FaaStRuby::Command::Credentials::Add,
      'list-credentials' => FaaStRuby::Command::Credentials::List,
      'help' => FaaStRuby::Command::Help,
      '-h' => FaaStRuby::Command::Help,
      '--help' => FaaStRuby::Command::Help,
      '-v' => FaaStRuby::Command::Version
    }
  end
end
