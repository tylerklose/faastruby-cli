require 'base64'

module FaaStRuby
  class Runner
    include RunnerMethods
    def initialize
      @rendered = false
    end

    def path
      @path
    end

    def call(workspace_name, function_name, event, args)
      @path = "#{FaaStRuby::PROJECT_ROOT}/#{workspace_name}/#{function_name}"
      begin
        load "#{@path}/handler.rb"
        Dir.chdir(@path)
        response = handler(event, *args)
        return response if response.is_a?(FaaStRuby::Response)
        body = {
          'error' => "Please use the helpers 'render' or 'respond_with' as your function return value."
        }
        FaaStRuby::Response.new(body: Oj.dump(body), status: 500, headers: {'Content-Type' => 'application/json'})
      rescue Exception => e
        body = {
          'error' => e.message,
          'location' => e.backtrace&.first,
        }
        FaaStRuby::Response.new(body: Oj.dump(body), status: 500, headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end