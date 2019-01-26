module FaaStRuby
  PROJECT_ROOT = Dir.pwd
  class DoubleRenderError < StandardError; end
  class EventChannel
    @@channels = {}
    def self.channels
      @@channels
    end
    attr_accessor :name
    def initialize(channel)
      @name = channel
      @@channels[channel] ||= []
    end
    def subscribe(function_path)
      @@channels[@name] << function_path
    end
    def subscribers
      @@channels[@name] || []
    end
  end
  class Subscriber
    attr_accessor :path
    def initialize(path)
      @path = path
      @workspace_name, @function_name = @path.split("/")
    end

    def call(encoded_data)
      data = Base64.urlsafe_decode64(encoded_data)
      headers = {'X-Origin' => 'event_hub', 'Content-Transfer-Encoding' => 'base64'}
      event = Event.new(data, {}, headers, nil)
      Runner.new.call(@workspace_name, @function_name, event, [])
    end
  end

  class EventHub
    @@queue = Queue.new
    def self.queue
      @@queue
    end

    def self.push(payload)
      @@queue << payload
    end

    def self.thread
      @@thread
    end

    def self.load_subscribers
      Dir.glob('*/*/faastruby.yml').each do |file|
        workspace_name, function_name, _ = file.split('/') 
        path = "#{workspace_name}/#{function_name}"
        config = YAML.load(File.read(file))
        next unless config['channels'].is_a?(Array)
        config['channels'].compact!
        config['channels'].each do |c|
          channel = EventChannel.new(c)
          channel.subscribe(path)
        end
      end
      puts "[EventHub] Channel subscriptions: #{EventChannel.channels}".yellow
      puts "[EventHub] If you modify 'faastruby.yml' in any function, you will need to restart the server to apply the changes.".yellow 
    end

    def self.listen_for_events!
      load_subscribers
      @@thread = Thread.new do
        loop do
          encoded_channel, encoded_data = @@queue.pop.split(',')
          channel = EventChannel.new(Base64.urlsafe_decode64(encoded_channel))
          puts "[EventHub] Event channel=#{channel.name.inspect}".yellow
          channel.subscribers.each do |s|
            subscriber = Subscriber.new(s)
            puts "[EventHub] Trigger function=#{subscriber.path.inspect} base64_payload=#{encoded_data.inspect}".yellow
            response = subscriber.call(encoded_data)
            puts "[#{subscriber.path}] #=> status=#{response.status} body=#{response.body.inspect} headers=#{Oj.dump response.headers}".light_blue
          end
        end
      end
      puts "[EventHub] Events thread started.".yellow
    end
  end

  class Runner
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

    def rendered!
      @rendered = true
    end
    def rendered?
      @rendered
    end

    def respond_with(body, status: 200, headers: {}, binary: false)
      raise FaaStRuby::DoubleRenderError.new("You called 'render' or 'respond_with' twice in your handler method") if rendered?
      response = FaaStRuby::Response.new(body: body, status: status, headers: headers, binary: binary)
      rendered!
      response
    end

    def render(
        js: nil,
        css: nil,
        body: nil,
        inline: nil,
        html: nil,
        json: nil,
        yaml: nil,
        text: nil,
        data: nil,
        png: nil,
        svg: nil,
        jpeg: nil,
        gif: nil,
        icon: nil,
        status: 200, headers: {}, content_type: nil, binary: false
      )
      headers["Content-Type"] = content_type if content_type
      bin = false
      case
      when json
        headers["Content-Type"] ||= "application/json"
        resp_body = json.is_a?(String) ? json : Oj.dump(json)
      when html, inline
        headers["Content-Type"] ||= "text/html"
        resp_body = html
      when text
        headers["Content-Type"] ||= "text/plain"
        resp_body = text
      when yaml
        headers["Content-Type"] ||= "application/yaml"
        resp_body = yaml.is_a?(String) ? yaml : YAML.load(yaml)
      when body
        headers["Content-Type"] ||= "application/octet-stream"
        bin = binary
        resp_body = bin ? Base64.urlsafe_encode64(body) : body
      when data
        headers["Content-Type"] ||= "application/octet-stream"
        resp_body = Base64.urlsafe_encode64(data)
        bin = true
      when js
        headers["Content-Type"] ||= "text/javascript"
        resp_body = js
      when css
        headers["Content-Type"] ||= "text/css"
        resp_body = css
      when png
        headers["Content-Type"] ||= "image/png"
        resp_body = Base64.urlsafe_encode64(png)
        bin = true
      when svg
        headers["Content-Type"] ||= "image/svg+xml"
        resp_body = svg
      when jpeg
        headers["Content-Type"] ||= "image/jpeg"
        resp_body = Base64.urlsafe_encode64(jpeg)
        bin = true
      when gif
        headers["Content-Type"] ||= "image/gif"
        resp_body = Base64.urlsafe_encode64(gif)
        bin = true
      when icon
        headers["Content-Type"] ||= "image/x-icon"
        resp_body = Base64.urlsafe_encode64(icon)
        bin = true
      end
      respond_with(resp_body, status: status, headers: headers, binary: bin)
    end

    def puts(msg)
      super "[#{@path}] #{msg}".green
    end

    def publish(channel, data: nil)
      begin
        encoded_data = data ? Base64.urlsafe_encode64(data, padding: false) : ""
        payload = %(#{Base64.urlsafe_encode64(channel, padding: false)},#{encoded_data})
        EventHub.queue.push payload
        true
      rescue
        false
      end
    end
  end

  class Event
    attr_accessor :body, :query_params, :headers, :context
    def initialize(body, query_params, headers, context)
      @body = body
      @query_params = query_params
      @headers = headers
      @context = context
    end
  end

  class Response
    attr_accessor :body, :status, :headers, :binary
    def initialize(body:, status: 200, headers: {}, binary: false)
      @body = body
      @status = status
      @headers = headers
      @binary = binary
    end

    def binary?
      @binary
    end
  end
end
