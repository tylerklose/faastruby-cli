require 'yaml'
require 'oj'
require 'faastruby-rpc'
require 'base64'
require 'faastruby/server'
require 'sinatra'
require 'sinatra/multi_route'
require 'colorize'
require 'filewatcher'
require 'securerandom'
module FaaStRuby
  SERVER_ROOT = Dir.pwd
  PROJECT_YAML_FILE = 'project.yml'
  FaaStRuby::EventHub.listen_for_events!
  FaaStRuby::Sentinel.start!
  class Server < Sinatra::Base
    set :show_exceptions, true
    register Sinatra::MultiRoute

    route :head, :get, :post, :put, :patch, :delete, '/*' do
      request_uuid = SecureRandom.uuid
      splat = params['splat'][0]
      case 
      when splat == ''
        path = YAML.load(File.read("#{PROJECT_ROOT}/#{PROJECT_YAML_FILE}"))['root_to']
      when !File.file?("#{PROJECT_ROOT}/#{splat}/faastruby.yml")
        path = YAML.load(File.read("#{PROJECT_ROOT}/#{PROJECT_YAML_FILE}"))['404_to']
      else
        path = splat
      end
      headers = env.select { |key, value| key.include?('HTTP_') || ['CONTENT_TYPE', 'CONTENT_LENGTH', 'REMOTE_ADDR', 'REQUEST_METHOD', 'QUERY_STRING'].include?(key) }
      if headers.has_key?("HTTP_FAASTRUBY_RPC")
        body = nil
        rpc_args = parse_body(request.body.read, headers['CONTENT_TYPE'], request.request_method) || []
      else
        body = parse_body(request.body.read, headers['CONTENT_TYPE'], request.request_method)
        rpc_args = []
      end
      query_params = parse_query(request.query_string)
      context = set_context(path)
      event = FaaStRuby::Event.new(body: body, query_params: query_params, headers: headers, context: context)
      puts "#{Time.now} [#{path.underline}] [#{request_uuid.underline}] <=[REQUEST: #{headers['REQUEST_METHOD']} #{request.fullpath}] body=\"#{body}\" query_params=#{query_params} headers=#{headers}".black.on_light_cyan
      time, response = FaaStRuby::Runner.new.call(path, event, rpc_args)
      status response.status
      headers response.headers
      if response.binary?
        response_body = Base64.urlsafe_decode64(response.body)
      else
        response_body = response.body
      end
      puts "#{Time.now} [#{path.underline}] [#{request_uuid.underline}] [RESPONSE: #{time}ms]=> status=#{response.status} body=#{response_body.inspect} headers=#{Oj.dump response.headers}".black.on_light_blue
      body response_body  
    end

    def parse_body(body, content_type, method)
      return nil if method == 'GET'
      return {} if body.nil? && method != 'GET'
      return Oj.load(body) if content_type == 'application/json'
      return body
    end

    def set_context(path)
      return nil
      # this should read from faastruby-workspace.yml
      # return nil unless File.file?('context.yml')
      # yaml = YAML.load(File.read('context.yml'))
      # return nil unless yaml.has_key?(workspace_name)
      # yaml[workspace_name][function_name]
    end

    def parse_query(query_string)
      hash = {}
      query_string.split('&').each do |param|
        key, value = param.split('=')
        hash[key] = value
      end
      hash
    end
  end
end