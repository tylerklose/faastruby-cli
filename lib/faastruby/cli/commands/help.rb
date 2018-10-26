module FaaStRuby
  module Command
    class Help < BaseCommand
      def initialize(args)
        @args = args
      end

      def run
        puts "FaaStRuby CLI - Manage workspaces and functions hosted at faastruby.io"
        puts
        puts 'help, -h, --help     # Displays this help'
        puts '-v                   # Print version and exit'
        puts
        workspaces = ["Workspaces:"]
        functions = ["Functions:"]
        credentials = ["Credentials:"]
        FaaStRuby::Command::COMMANDS.each do |command, klass|
          next if command == 'upgrade'
          next if klass.to_s.match(/.+Command::Help$/)
          next if klass.to_s.match(/.+Command::Version$/)
          section = functions if klass.to_s.match(/.+::Function::.+/)
          section = workspaces if klass.to_s.match(/.+::Workspace::.+/)
          section = credentials if klass.to_s.match(/.+::Credentials::.+/)
          section ||= []
          section << "  #{klass.help}"
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