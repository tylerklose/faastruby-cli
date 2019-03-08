module FaaStRuby
  module Command
    require 'faastruby/cli/commands'
    class Help < BaseCommand
      def initialize(args)
        @args = args
      end

      def run
        puts "FaaStRuby CLI - Manage workspaces and functions hosted at faastruby.io"
        puts "Version: #{FaaStRuby::VERSION}"
        puts
        puts "Usage: faastruby [OPTIONS] COMMAND [--help | -h] [ARGS]"
        puts
        puts "OPTIONS:"
        puts 'help, -h, --help     # Displays this help'
        puts '-v                   # Print version and exit'
        puts '--region tor1        # Specify a region. "tor1" (default) is the only region available'
        puts "\nCOMMANDS:"
        puts %(
Accounts:
  signup
  confirm-account      # Send a code over email for account confirmation
  login
  logout

Functions:
  new                  # Initialize a function in your local machine
  deploy-to            # Deploy a function to a cloud workspace
  remove-from          # Remove a function from a cloud workspace
  run                  # Trigger the function via HTTP endpoint
  update-context       # Update the context data for a function

Projects:
  new                  # Initialize a project in your local machine
  deploy               # Deploy all functions and static files of a project

Workspaces:
  create-workspace     # Create a cloud workspace
  destroy-workspace    # Erase a workspace from the cloud
  list-workspace       # List what's in a cloud workspace
  cp                   # Copy a static file from your local machine to a cloud workspace
  rm                   # Remove a static file from a cloud workspace
  update-workspace     # Update workspace settings

)
        # workspaces = ["Workspaces:"]
        # functions = ["Functions:"]
        # account = ["Account:"]
        # FaaStRuby::Command::COMMANDS.each do |command, klass|
        #   next if command == 'upgrade'
        #   next if klass.call.to_s.match(/.+Command::Help$/)
        #   next if klass.call.to_s.match(/.+Command::Version$/)
        #   section = functions if klass.call.to_s.match(/.+::Function::.+/)
        #   section = workspaces if klass.call.to_s.match(/.+::Workspace::.+/)
        #   section = credentials if klass.call.to_s.match(/.+::Credentials::.+/)
        #   section ||= []
        #   section << "  #{klass.call.help}"
        # end
        # puts workspaces
        # puts
        # puts functions
        # puts
        # puts credentials
        # puts
      end
    end
  end
end
