module FaaStRuby
  require 'base64'
  class InvalidResponseError < StandardError
    def initialize(msg)
      msg = "You must use the method 'render' within your function handler."
    end
  end
  class Response
    def self.error(error)
      new(
        body: error,
        status: 500,
        headers: {'Content-Type' => 'application/json'}
      )
    end
    def self.request_limit_reached(workspace: nil, function: nil)
      body = {'error' => "Concurrent requests limit reached. Please add more runners to the workspace #{workspace}."} if workspace
      # body = {'error' => "Concurrent requests limit reached for function '#{workspace}/#{function}'. Please associate more runners."} if function
      body = Oj.dump(body)
      new(
        body: body,
        status: 422,
        headers: {'Content-Type' => 'application/json'}
      )
    end

    def self.invalid_response
      body = {'error' => "Your function must render a response. For example, render text: \"Hello World!\". If you want to respond with an empty body, use 'render_nothing'."}
      body = Oj.dump(body)
      new(
        body: body,
        status: 500,
        headers: {'Content-Type' => 'application/json'}
      )
    end

    def self.from_payload(payload)
      from_json Base64.urlsafe_decode64(payload)
    end
    def self.from_json(json)
      hash = Oj.load(json)
      new(
        body: hash['body'],
        status: hash['status'],
        headers: hash['headers'],
        binary: hash['binary']
      )
    end
    attr_accessor :body, :status, :headers, :binary
    def initialize(body:, status: 200, headers: {}, binary: false)
      if body.is_a?(String) || body.nil?
        @body = body
      else
        @body = body.inspect
      end
      @status = status
      @headers = headers
      @binary = binary
    end

    def to_json
      hash = {
        'body' => body,
        'status' => status,
        'headers' => headers,
        'binary' => binary
      }
      Oj.dump(hash)
    end

    def payload
      Base64.urlsafe_encode64(to_json, padding: false)
    end

    def binary?
      @binary
    end
  end
end