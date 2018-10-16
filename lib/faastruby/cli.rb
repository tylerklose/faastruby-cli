require 'tty-spinner'
require 'yaml'
require 'tty-table'
require 'zip'
require 'colorize'
require 'faastruby/cli/commands'
require 'faastruby/cli/package'

module FaaStRuby
  FAASTRUBY_YAML = 'faastruby.yml'
  FAASTRUBY_CREDENTIALS = File.expand_path(ENV['FAASTRUBY_CREDENTIALS'] || '~/.faastruby')
  SPINNER_FORMAT = :spin_2

  class CLI
    def self.error(message, color: :red)
      message.each {|m| STDERR.puts m.colorize(color)} if message.is_a?(Array)
      STDERR.puts message.colorize(color) if message.is_a?(String)
      exit 1
    end

    def self.run(command, args)
      if command.nil?
        FaaStRuby::Command::Help.new(args).run
        return
      end
      check_version
      error("Unknown command: #{command}") unless FaaStRuby::Command::COMMANDS.has_key?(command)
      FaaStRuby::Command::COMMANDS[command].new(args).run
    end

    def self.check_version
      latest = RestClient.get('https://faastruby.io/gem/minimum.txt').body rescue '0.0.1'
      if Gem::Version.new(FaaStRuby::VERSION) < Gem::Version.new(latest)
        FaaStRuby.error([
          "You are using an old version of the gem. Please run 'gem update faastruby'.".red,
          "Installed version: #{FaaStRuby::VERSION}",
          "Latest version: #{latest}"
        ], color: nil)
      end
    end
  end
end
