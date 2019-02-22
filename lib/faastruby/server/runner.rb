require 'base64'
require 'open3'
module FaaStRuby
  class Runner
    include RunnerMethods
    def initialize
      @rendered = false
    end

    def path
      @path
    end

    def load_function(path)
      eval "Module.new do; #{File.read(path)};end"
    end

    def call(short_path, event, args)
      @short_path = short_path
      @path = "#{FaaStRuby::PROJECT_ROOT}/#{short_path}"
      # unless File.file?("#{@path}/faastruby.yml")
      #   @path = YAML.load(File.read("#{PROJECT_ROOT}/#{PROJECT_YAML_FILE}"))['error_pages']['404_to']
      # end
      # puts @path
      begin
        runtime, version = (YAML.load(File.read("#{@path}/faastruby.yml"))['runtime'] || 'ruby:2.5.3').split(':')
        case runtime
        when 'ruby'
          time, response = call_ruby(event, args)
        when 'crystal'
          time, response = call_crystal(event, args)
        else
          puts "[Runner] ERROR: could not determine runtime for function #{@short_path}.".red
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
      runner = FunctionObject.new(@short_path)
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      response = CHDIR_MUTEX.synchronize do
        Dir.chdir(@path)
        function = load_function("#{@path}/handler.rb")
        runner.extend(function)
        runner.handler(event, *args)
      end
      time_finish = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      time = (time_finish - time_start).round(2)
      [time, response]
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
      cmd = "#{@path}/handler"
      # STDOUT.puts "Running #{cmd}"
      output = nil
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      Open3.popen2(cmd, chdir: @path) do |stdin, stdout, status|
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
        headers: response_obj['headers']
      )
      [time, response]
    end
  end
end