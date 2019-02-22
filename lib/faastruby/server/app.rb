require 'yaml'
require 'oj'
require 'faastruby-rpc'
require 'base64'
require 'faastruby/server'
require 'sinatra'
require 'sinatra/multi_route'
require 'filewatcher'
require 'securerandom'
require 'rouge'
require 'colorize'
module FaaStRuby
  SERVER_ROOT = Dir.pwd
  PROJECT_YAML_FILE = 'project.yml'
  OUTPUT_MUTEX = Mutex.new
  FaaStRuby::EventHub.listen_for_events!
  FaaStRuby::Sentinel.start!
  class Server < Sinatra::Base
    include FaaStRuby::Logger::Requests
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
      # headers = env.select {|key, value| key.include?('HTTP_') || ['CONTENT_TYPE', 'CONTENT_LENGTH', 'REMOTE_ADDR', 'REQUEST_METHOD', 'QUERY_STRING'].include?(key) }
      headers = parse_headers(env)
      if headers.has_key?("Faastruby-Rpc")
        body = nil
        rpc_args = parse_body(request.body.read, headers['Content-Type'], request.request_method) || []
      else
        body = parse_body(request.body.read, headers['Content-Type'], request.request_method)
        rpc_args = []
      end
      headers['X-Request-Id'] = request_uuid
      headers['Request-Method'] = request.request_method
      original_request_id = headers['X-Original-Request-Id']
      query_params = parse_query(request.query_string)
      context = set_context(path)
      event = FaaStRuby::Event.new(body: body, query_params: query_params, headers: headers, context: context)
      puts "[#{path}] <- [REQUEST: #{request.request_method} \"#{request.fullpath}\"] request_id=\"#{request_uuid}\" body=\"#{body}\" query_params=#{query_params} headers=#{headers}"
      time, response = FaaStRuby::Runner.new.call(path, event, rpc_args)
      status response.status
      response.headers['X-Request-Id'] = request_uuid
      response.headers['X-Original-Request-Id'] = original_request_id if original_request_id
      response.headers['X-Execution-time'] = "#{time}ms"
      headers response.headers
      if response.binary?
        response_body = Base64.urlsafe_decode64(response.body)
        print_body = "Base64(#{response.body})"
      else
        response_body = response.body
        print_body = response_body
      end
      puts "[#{path}] -> [RESPONSE: #{time}ms] request_id=\"#{request_uuid}\" status=#{response.status} body=#{print_body.inspect} headers=#{response.headers}"
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
      # this should read from secrets.yml
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

    def parse_headers(env)
      Hash[*env.select {|k,v| k.start_with? 'HTTP_'}
        .collect {|k,v| [k.sub(/^HTTP_/, ''), v]}
        .collect {|k,v| [k.split('_').collect{|a|k == 'DNT' ? k : k.capitalize}.join('-'), v]}
        .sort
        .flatten]
    end
  end
end