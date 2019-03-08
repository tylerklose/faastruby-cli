module FaaStRuby
  module Command
    module Function
      require 'faastruby/cli/commands/function/base_command'
      class Run < FunctionBaseCommand
        def initialize(args)
          @args = args
          help
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @options = {}
          @options['workspace_name'] = @args.shift
          load_yaml
          @function_name = @yaml_config['name']
          parse_options
          @options['query'] = "?#{@options['query'].join('&')}" if @options['query']&.any?
        end

        def run
          return curl if @options['curl']
          function = FaaStRuby::Function.new(name: @function_name)
          response = function.run(@options)
          puts response.body
        end

        def curl
          command = ["curl"]
          command << "-X #{@options['method'].upcase}" if @options['method']
          @options['headers']&.each {|h,v| command << "-H '#{h}: #{v}'"}
          command << "-d '#{@options['body']}'" if @options['body']
          command << "'#{FaaStRuby.api_host}/#{@options['workspace_name']}/#{@function_name}#{@options['query']}'"
          puts command.join(" ")
        end

        def self.help
          'run WORKSPACE_NAME [ARGS]'
        end

        def usage
          puts "\nUsage: faastruby #{self.class.help}"
          puts %(
-b,--body 'DATA'               # The request body
--stdin                        # Read the request body from STDIN
-m,--method METHOD             # The request method
-h,--header 'Header: Value'    # Set a header. Can be used multiple times.
-f,--form 'a=1&b=2'            # Send form data and set header 'Content-Type: application/x-www-form-urlencoded'
-j,--json '{"a":"1"}'          # Send JSON data and set header 'Content-Type: application/json'
-t,--time                      # Return function run time in the response
-q,--query 'foo=bar'           # Set a query parameter for the request. Can be used multiple times.
--curl                         # Return the CURL command equivalent for the request
          )
        end

        private

        def parse_options
          while @args.any?
            option = @args.shift
            case option
            when '-b', '--body'
              set_body
            when '-j', '--json'
              set_json
            when '-f', '--form'
              set_form
            when '--stdin'
              set_stdin
            when '-m', '--method'
              @options['method'] = @args.shift.downcase
            when '-h', '--header'
              set_header
            when '-t', '--time'
              @options['time'] = true
            when '--curl'
              @options['curl'] = true
            when '-q', '--query'
              set_query
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def set_body
          @options['method'] ||= 'post'
          @options['body'] = @args.shift
          default_content_type = 'text/plain'
          @options['headers'] ? @options['headers']['Content-Type'] = default_content_type : @options['headers'] = {'Content-Type' => default_content_type}
        end

        def set_json
          content_type = 'application/json'
          @options['method'] ||= 'post'
          @options['body'] = @args.shift
          @options['headers'] ? @options['headers']['Content-Type'] = content_type : @options['headers'] = {'Content-Type' => content_type}
        end

        def set_form
          content_type = 'application/x-www-form-urlencoded'
          @options['method'] ||= 'post'
          @options['body'] = @args.shift
          @options['headers'] ? @options['headers']['Content-Type'] = content_type : @options['headers'] = {'Content-Type' => content_type}
        end

        def set_stdin
          @options['method'] ||= 'post'
          @options['body'] = STDIN.gets.chomp
          content_type = 'text/plain'
          @options['headers'] ? @options['headers']['Content-Type'] = content_type : @options['headers'] = {'Content-Type' => content_type}
        end

        def set_query
          query = "#{@args.shift}"
          @options['query'] ? @options['query'] << query : @options['query'] = [query]
        end

        def set_header
          header = @args.shift
          key, value = header.split(":")
          value.strip!
          @options['headers'] ? @options['headers'][key] = value : @options['headers'] = {key => value}
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: WORKSPACE_NAME".red
            @missing_args << usage
          end
          FaaStRuby::CLI.error(["'#{@args.first}' is not a valid workspace name.".red, usage], color: nil) if @args.first =~ /^-.*/
          @missing_args
        end
      end
    end
  end
end
