require 'rest-client'

module FaaStRuby
  class API
    @@api_version = 'v2'
    attr_reader :api_url, :credentials, :headers
    def initialize
      @api_url = "#{HOST}/#{@@api_version}"
      @credentials = {'API-KEY' => FaaStRuby.api_key, 'API-SECRET' => FaaStRuby.api_secret}
      @headers = {content_type: :json, accept: :json}.merge(@credentials)
    end

    def create_workspace(workspace_name:, email: nil)
      url = "#{@api_url}/workspaces"
      payload = {'name' => workspace_name}
      payload['email'] = email if email
      parse RestClient.post(url, Oj.dump(payload), @headers){|response, request, result| response }
    end

    def destroy_workspace(workspace_name)
      url = "#{@api_url}/workspaces/#{workspace_name}"
      parse RestClient.delete(url, @headers){|response, request, result| response }
    end

    # def update_workspace(workspace_name, payload)
    #   url = "#{@api_url}/workspaces/#{workspace_name}"
    #   parse RestClient.patch(url, Oj.dump(payload), @headers)
    # end

    def get_workspace_info(workspace_name)
      url = "#{@api_url}/workspaces/#{workspace_name}"
      parse RestClient.get(url, @headers){|response, request, result| response }
    end

    def deploy(workspace_name:, package:)
      url = "#{@api_url}/workspaces/#{workspace_name}/deploy"
      payload = {package: File.new(package, 'rb')}
      parse RestClient.post(url, payload, @credentials){|response, request, result| response }
    end

    def delete_from_workspace(function_name:, workspace_name:)
      url = "#{@api_url}/workspaces/#{workspace_name}/functions/#{function_name}"
      parse RestClient.delete(url, @headers){|response, request, result| response }
    end

    # def list_workspace_functions(workspace_name)
    #   url = "#{@api_url}/workspaces/#{workspace_name}/functions"
    #   parse RestClient.get(url, @headers){|response, request, result| response }
    # end

    def run(function_name:, workspace_name:, payload:, method:, headers: {}, time: false, query: nil)
      url = "#{HOST}/#{workspace_name}/#{function_name}#{query}"
      headers['Benchmark'] = true if time
      if method == 'get'
        RestClient.public_send(method, url, headers){|response, request, result| response }
      else
        RestClient.public_send(method, url, payload, headers){|response, request, result| response }
      end
    end

    def update_function_context(function_name:, workspace_name:, payload:)
      # payload is a string
      url = "#{@api_url}/workspaces/#{workspace_name}/functions/#{function_name}"
      parse RestClient.patch(url, Oj.dump(payload), @headers){|response, request, result| response }
    end

    def parse(response)
      struct = Struct.new(:response, :body, :errors, :code)
      case response.code
      when 401
        body = Oj.load(response.body)
        return struct.new(nil, nil, ["(401) Unauthorized - #{body['error']}"], 401)
      when 404
        body = Oj.load(response.body)
        return struct.new(nil, nil, ["(404) Not Found - #{body['error']}"], 404)
      when 409
        body = Oj.load(response.body)
        return struct.new(nil, nil, ["(409) Conflict - #{body['error']}"], 409)
      when 500
        return struct.new(nil, nil, ["(500) Error"], 500)
      when 408
        return struct.new(nil, nil, ["(408) Request Timeout"], 408)
      when 422
        body = Oj.load(response.body)
        errors = ["(422) Unprocessable Entity"]
        errors << body['error'] if body['error']
        errors += body['errors'] if body['errors']
        return struct.new(nil, nil, errors, 422)
      when 402 # Limit excedeed
        body = Oj.load(response.body)
        return struct.new(nil, nil, ["(402) Limit Exceeded - #{body['error']}"], 402)
      else
        body = Oj.load(response.body)
        return struct.new(response, body, (body['errors'] || []), response.code)
      end
    end
  end
end