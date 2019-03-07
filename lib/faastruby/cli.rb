require 'colorize'

module FaaStRuby
  FUNCTION_NAME_REGEX = '[a-zA-Z\-_0-9\/\.]{1,}'
  WORKSPACE_NAME_REGEX = '[a-zA-Z0-im9_]{1}[a-zA-Z0-9\-]{1,}[a-zA-Z0-9_]{1}'
  FAASTRUBY_YAML = 'faastruby.yml'
  SPINNER_FORMAT = :spin_2

  class CLI
    def self.error(message, color: :red)
      message.each {|m| STDERR.puts m.colorize(color)} if message.is_a?(Array)
      STDERR.puts message.colorize(color) if message.is_a?(String)
      exit 1
    end

    def self.run(command, args)
      if command.nil?
        require 'faastruby/cli/commands/help'
        FaaStRuby::Command::Help.new(args).run
        return
      end
      check_ruby_version
      start_server(args) if command == 'local'
      start_tmuxinator if command == 'mux'
      # check_version
      check_region
      require 'faastruby/cli/commands'
      # require 'faastruby/cli/package'
      # require 'faastruby/cli/template'
      error("Unknown command: #{command}") unless FaaStRuby::Command::COMMANDS.has_key?(command)

      const = FaaStRuby::Command::COMMANDS[command].call
      const.new(args).run
    end

    # def self.check_version
    #   latest = RestClient.get('https://faastruby.io/gem/minimum.txt').body rescue '0.0.1'
    #   if Gem::Version.new(FaaStRuby::VERSION) < Gem::Version.new(latest)
    #     FaaStRuby.error([
    #       "You are using an old version of the gem. Please run 'gem update faastruby'.".red,
    #       "Installed version: #{FaaStRuby::VERSION}",
    #       "Latest version: #{latest}"
    #     ], color: nil)
    #   end
    # end

    def self.check_ruby_version
      require 'faastruby/supported_runtimes'
      error("Unsupported Ruby version: #{RUBY_VERSION}\nSupported Ruby versions are: #{SUPPORTED_RUBY.join(", ")}") unless SUPPORTED_RUBY.include?(RUBY_VERSION)
    end

    def self.check_region
      ENV['FAASTRUBY_REGION'] ||= DEFAULT_REGION
      error(["No such region: #{ENV['FAASTRUBY_REGION']}".red, "Valid regions are:  #{FaaStRuby::REGIONS.join(' | ')}"], color: nil) unless FaaStRuby::REGIONS.include?(ENV['FAASTRUBY_REGION'])
    end

    def self.start_server(args)
      parsed = []
      parsed << 'FAASTRUBY_PROJECT_SYNC_ENABLED=true' if args.delete('--sync')
      parsed << 'DEBUG=true' if args.delete('--debug')
      args.each_with_index do |arg, i|
        if arg == '--deploy-env'
          args.delete_at(i)
          parsed << "FAASTRUBY_PROJECT_DEPLOY_ENVIRONMENT=#{args.delete_at(i)}"
        end
      end
      server_dir = "#{Gem::Specification.find_by_name("faastruby").gem_dir}/lib/faastruby/server"
      config_ru = "#{server_dir}/config.ru"
      puma_config = "#{server_dir}/puma.rb"
      exec "#{parsed.join(' ')} puma -C #{puma_config} #{args.join(' ')} #{config_ru}"
    end
    def self.start_tmuxinator
      if system("tmux -V > /dev/null")
        project_name = YAML.load(File.read("project.yml"))['name']
        exec("tmuxinator start #{project_name} -p tmuxinator.yml")
      else
        error("To use 'faastruby mux' you need to have 'tmux' installed.", color: nil)
      end
    end
  end
end
