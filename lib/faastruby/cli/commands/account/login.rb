module FaaStRuby
  module Command
    module Account
      require 'faastruby/cli/commands/account/base_command'
      require 'io/console'
      class Login < AccountBaseCommand
        def initialize(args)
          @args = args
          parse_options
          @email = @options['email']
          @password = @options['password']
        end

        def run
          ask_for_email unless @email
          ask_for_password unless @password
          user = User.new(email: @email, password: @password)
          user.login
          FaaStRuby::CLI.error(user.errors) if user&.errors.any?
          user.save_credentials
          puts "Login successful."
          migrate
        end

        def ask_for_email
          print "Email: "
          @email = STDIN.gets.chomp
        end

        def ask_for_password
          print "Password: "
          @password = STDIN.noecho(&:gets).chomp
          puts "\n"
        end

        def migrate
          old_credentials = File.expand_path("~/.faastruby.tor1")
          return unless File.file?(old_credentials)
          puts "ATTENTION: I've detected you have workspace credentials saved in '#{old_credentials}'.".red
          puts "You need to migrate these credentials into your account."
          print "Do you want to do it right now? [Y/n] "
          answer = STDIN.gets.chomp
          if answer == 'n'
            puts "You won't be able to manage these workspaces until you perform this migration."
            puts "When you are ready to perform this migration, run 'faastruby migrate-workspaces'."
            exit 0
          else
            exec("faastruby migrate-workspaces")
          end
        end

        def self.help
          "login [ARGS]"
        end

        def usage
          puts "Usage: faastruby #{self.class.help}"
          puts %(
-e,--email EMAIL         # Your email
-p,--password PASSWORD   # Your password
          )
        end

        private

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-h', '--help', 'help'
              puts usage
              exit 0
            when '-e', '--email'
              @options['email'] = @args.shift
            when '-p', '--password'
              @options['password'] = @args.shift
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end
