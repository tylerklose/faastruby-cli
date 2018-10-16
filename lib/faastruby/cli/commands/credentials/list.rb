module FaaStRuby
  module Command
    module Credentials
      class List < CredentialsBaseCommand
        def initialize(args)
          @args = args
          parse_options
          @options['credentials_file'] ||= FAASTRUBY_CREDENTIALS
        end

        def run
          FaaStRuby::CLI.error("The file '#{@options['credentials_file']}' does not exist.") unless File.file?(@options['credentials_file'])
          rows = []
          credentials = FaaStRuby::Credentials.load_credentials_file(@options['credentials_file'])
          FaaStRuby::CLI.error("The credentials file '#{@options['credentials_file']}' is empty.") unless credentials.any?
          credentials.each do |workspace, credentials|
            rows << [workspace, credentials['api_key'], credentials['api_secret']]
          end
          table = TTY::Table.new(['Workspace','API_KEY', 'API_SECRET'], rows)
          puts table.render(:basic)
        end

        def self.help
          "list-credentials".blue + " [-c CREDENTIALS_FILE]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def missing_args
          @missing_args << "Missing argument: CREDENTIALS_FILE".red unless @options['credentials_file']
          @missing_args << usage if @missing_args.any?
          @missing_args
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-c', '--credentials-file'
              @options['credentials_file'] = @args.shift
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end
