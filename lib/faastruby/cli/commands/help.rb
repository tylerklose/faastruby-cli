module FaaStRuby
  module Command
    require 'faastruby/cli/commands'
    class Help < BaseCommand
      def initialize(args)
        @args = args
      end

      def run
        puts "FaaStRuby CLI - Manage workspaces and functions hosted at faastruby.io"
        puts
        puts "Usage: faastruby [--region REGION, -h, -v] COMMAND ARGS"
        puts
        puts 'help, -h, --help     # Displays this help'
        puts '-v                   # Print version and exit'
        puts '--region tor1        # Specify a region. "tor1" (default) is the only region available'
        workspaces = ["Workspaces:"]
        functions = ["Functions:"]
        credentials = ["Credentials:"]
        FaaStRuby::Command::COMMANDS.each do |command, klass|
          next if command == 'upgrade'
          next if klass.call.to_s.match(/.+Command::Help$/)
          next if klass.call.to_s.match(/.+Command::Version$/)
          section = functions if klass.call.to_s.match(/.+::Function::.+/)
          section = workspaces if klass.call.to_s.match(/.+::Workspace::.+/)
          section = credentials if klass.call.to_s.match(/.+::Credentials::.+/)
          section ||= []
          section << "  #{klass.call.help}"
        end
        puts workspaces
        puts
        puts functions
        puts
        puts credentials
        puts
      end
    end
  end
end
