module FaaStRuby
  module Command
    module Account
      PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,20}$/
      EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      require 'faastruby/cli/commands/account/base_command'
      require 'io/console'
      class Signup < AccountBaseCommand
        def initialize(args)
          @args = args
          parse_options
          FaaStRuby::CLI.error("You are currently logged in. Please run 'faastruby logout' to logout, then try again.") if has_user_logged_in?
        end

        def run
          puts "\nWelcome to FaaStRuby! Please enter your email address:"
          print "Email: "
          email = STDIN.gets.chomp
          until email_is_valid?(email) do
            puts "You entered an invalid email address. Please try again:".red
            print "Email: "
            email = STDIN.gets.chomp
          end
          puts "\nNow type in a password. It must contain 8 to 20 characters and have at least one uppercase letter, one lowercase letter, one number."
          print "Password: "
          password = STDIN.noecho(&:gets).chomp
          until password_is_valid?(password) do
            puts "\nYour password must contain 8 to 20 characters and have at least one uppercase letter, one lowercase letter, one number. Please try again:".red
            print "Password: "
            password = STDIN.noecho(&:gets).chomp
          end
          spinner = spin("Creating your account...")
          user = User.create(email: email, password: password)
          if user.errors.any?
            spinner.stop(" Failed :(")
            FaaStRuby::CLI.error(user.errors)
          end
          spinner.stop(' Done!')
          exec("faastruby confirm-account --email #{email}")
          exit 0
        end

        def email_is_valid?(email)
          email.match(EMAIL_REGEX)
        end

        def password_is_valid?(password)
          password.match(PASSWORD_REGEX)
        end

        def self.help
          "signup"
        end

        def usage
          puts "Usage: faastruby #{self.class.help}"
        end


        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-h', '--help', 'help'
              usage
              exit 0
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end
