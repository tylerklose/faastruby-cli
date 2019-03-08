
module FaaStRuby
  module Command
    module Account
      require 'faastruby/cli/commands/account/base_command'
      class Confirm < AccountBaseCommand
        def initialize(args)
          @args = args
          parse_options
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
        end

        def run
          user = User.new(email: @options['email'])
          user.send_confirmation_code
          puts "\nYou should have received an email with a confirmation token. If you didn't receive an email, make sure you sign up with the correct email address."
          print "Confirmation Token: "
          user.confirmation_token = STDIN.gets.chomp
          spinner = spin("Confirming your account...")
          user.confirm_account!
          FaaStRuby::CLI.error(user.errors) if user.errors.any?
          spinner.stop(" Done!")
          user.save_credentials
          puts "Login successful!"
          migrate
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
          "confirm-account [ARGS]"
        end

        def usage
          puts "Usage: faastruby #{self.class.help}"
          puts %(
-e,--email EMAIL      # Your email
          )
        end

        private

        def missing_args
          @missing_args << "Missing argument: --email EMAIL".red unless @options['email']
          @missing_args << usage if @missing_args.any?
          @missing_args
        end

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
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end












