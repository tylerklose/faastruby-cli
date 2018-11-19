module FaaStRuby
  module Command
    module Credentials
      class Add < CredentialsBaseCommand
        def initialize(args)
          @args = args
          @workspace_name = @args.shift
          FaaStRuby::CLI.error(['Missing argument: WORKSPACE_NAME'.red, usage], color: nil) if @workspace_name.nil? || @workspace_name =~ /^-.*/
          parse_options
          @options['credentials_file'] ||= FaaStRuby.credentials_file
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
        end

        def run
          new_credentials = {'api_key' => @options['api_key'], 'api_secret' => @options['api_secret']}
          FaaStRuby::Credentials.add(@workspace_name, new_credentials, @options['credentials_file'])
          puts "Credentials file updated."
        end

        def self.help
          "add-credentials".blue + " WORKSPACE_NAME -k API_KEY -s API_SECRET [-c CREDENTIALS_FILE]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def missing_args
          @missing_args << "Missing argument: API_KEY".red unless @options['api_key']
          @missing_args << "Missing argument: API_SECRET".red unless @options['api_secret']
          @missing_args << "Missing argument: CREDENTIALS_FILE".red unless @options['credentials_file']
          @missing_args << usage if @missing_args.any?
          @missing_args
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-k', '--api-key'
              @options['api_key'] = @args.shift
            when '-c', '--credentials-file'
              @options['credentials_file'] = @args.shift
            when '-s', '--api-secret'
              @options['api_secret'] = @args.shift
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end
