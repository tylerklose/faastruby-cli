require 'base64'
require 'open3'
module FaaStRuby
  # require 'faastruby/server/response'
  # require 'faastruby/server/runner_methods'
  # require 'faastruby/server/function_object'
  class Runner
    def initialize(function_name)
      # puts "initializing runner for function name #{function_name}"
      @rendered = false
      @function_name = function_name
      @function_folder = "#{FaaStRuby::ProjectConfig.functions_dir}/#{function_name}"
      # puts "function_folder: #{@function_folder}"
      @config_file = "#{@function_folder}/faastruby.yml"
      # puts "reading config file #{@config_file}"
      @config = YAML.load(File.read(@config_file))
      @language, @version = (@config['runtime'] || DEFAULT_RUBY_RUNTIME).split(':')
    end

    def load_function(path)
      eval %(
        module Kernel
          # make an alias of the original require
          alias_method :original_require, :require

          # rewrite require
          def require name
            return load("\#{name}.rb") if File.file?("\#{name}.rb")
            original_require name
          end
        end

        Module.new do
          #{File.read(path)}
        end
      )
    end

    def call(event, args)
      begin
        case @language
        when 'ruby'
          time, response = call_ruby(event, args)
        when 'crystal'
          time, response = call_crystal(event, args)
        else
          puts "[Runner] ERROR: could not determine the language for function #{@function_name}.".red
        end
        return [time, response] if response.is_a?(FaaStRuby::Response)
        body = {
          'error' => "Please use the helpers 'render' or 'respond_with' as your function return value."
        }
        [time, FaaStRuby::Response.new(body: Oj.dump(body), status: 500, headers: {'Content-Type' => 'application/json'})]
      rescue Exception => e
        STDOUT.puts e.full_message
        body = {
          'error' => e.message,
          'location' => e.backtrace&.first,
        }
        [0.0, FaaStRuby::Response.new(body: Oj.dump(body), status: 500, headers: {'Content-Type' => 'application/json'})]
      end
    end
    def call_ruby(event, args)
      function_object = FunctionObject.new(@function_name)
      reader, writer = IO.pipe
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      pid = fork do
        # puts "loading #{@function_folder}/handler.rb"
        Dir.chdir(@function_folder)
        begin
          function = load_function("#{@function_folder}/handler.rb")
          function_object.extend(function)
          response = function_object.handler(event, *args) || function_object.render_nothing
          response = FaaStRuby::Response.invalid_response unless response.is_a?(FaaStRuby::Response)
        rescue Exception => e
          error = Oj.dump({
            'error' => e.message,
            'location' => e.backtrace&.first
          })
          response = FaaStRuby::Response.error(error)
        end
        writer.puts response.payload
        writer.close
        exit 0
      end
      response = FaaStRuby::Response.from_payload reader.gets.chomp
      reader.close
      Process.wait(pid)
      time_finish = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      time = (time_finish - time_start).round(2)
      [time, response]
    end

    def chdir
      CHDIR_MUTEX.synchronize do
        # puts "Switching to directory #{@function_folder}"
        Dir.chdir(@function_folder)
        yield
      end
    end

    def call_crystal(event, args)
      ####
      # This is a hack to address the bug https://github.com/crystal-lang/crystal/issues/7052
      event.query_params.each do |k, v|
        event.query_params[k] = '' if v.nil?
      end
      event.headers.each do |k, v|
        event.headers[k] = '' if v.nil?
      end
      ####
      payload_json = Oj.dump({'event' => event.to_h, 'args' => []})
      payload = Base64.urlsafe_encode64(payload_json, padding: false)
      cmd = "./handler"
      # STDOUT.puts "Running #{cmd}"
      # STDOUT.puts "From #{@function_folder}"
      output = nil
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      Open3.popen2(cmd, chdir: @function_folder) do |stdin, stdout, status|
        stdin.puts payload
        stdout.each_line do |line|
          if line[0..1] == 'R,'
            output = line.chomp
            break
          else
            puts line.chomp
          end
        end
      end
      time_finish = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      time = (time_finish - time_start).round(2)
      tag, o = output.split(',')
      decoded_response = Base64.urlsafe_decode64(o)
      response_obj = Oj.load(decoded_response)
      # STDOUT.puts response_obj
      response = FaaStRuby::Response.new(
        body: response_obj['response'],
        status: response_obj['status'],
        headers: response_obj['headers'],
        binary: response_obj['binary']
      )
      [time, response]
    end
  end
end