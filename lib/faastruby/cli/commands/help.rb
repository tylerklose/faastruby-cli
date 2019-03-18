module FaaStRuby
  module Command
    require 'faastruby/cli/base_command'
    class Help < BaseCommand
      def initialize(args)
        @args = args
      end

      def run
        puts %(
faastRuby CLI - Manage workspaces and functions hosted at faastruby.io
Version: #{FaaStRuby::VERSION}

Usage: faastruby [update] [OPTIONS] COMMAND [--help | -h] [ARGS]

To update to the latest version, run: faastruby update

OPTIONS:
  help, -h, --help     # Displays this help
  -v                   # Print version and exit
  --region tor1        # Specify a region. "tor1" (default) is the only
                       #  region available at this time

COMMANDS:

Accounts:
  signup
  confirm-account      # Send a token over email for account confirmation
  login
  logout

Functions:
  new                  # Initialize a directory with a function template
  deploy-to            # Deploy a function to a cloud workspace
  remove-from          # Remove a function from a cloud workspace
  run                  # Trigger the function via HTTP endpoint
  update-context       # Update the context data for a function

Projects:
  new-project          # Initialize a project in your local machine
  deploy               # Deploy all functions and static files of a project
  down                 # Remove a workspace from the cloud. Must be executed
                       #  from within a project directory.

Workspaces:
  create-workspace     # Create a cloud workspace
  destroy-workspace    # Remove a workspace and all its functions
                       #  from the cloud. Can't be undone.
  list-workspace       # List what's in a cloud workspace
  cp                   # Copy a static file from your local machine to
                       #  a cloud workspace
  rm                   # Remove a static file from a cloud workspace
  update-workspace     # Update workspace settings

Run faastruby COMMAND --help for more details.

)
      end
    end
  end
end
