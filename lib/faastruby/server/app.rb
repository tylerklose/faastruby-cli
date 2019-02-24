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

  FaaStRuby::EventHub.listen_for_events!
  FaaStRuby::Sentinel.start!

  class Server < Sinatra::Base
    include FaaStRuby::Logger::Requests
    set :show_exceptions, true
    set :root, SERVER_ROOT
    puts "Using public folder: #{FaaStRuby::ProjectConfig.public_dir}"
    set :public_folder, FaaStRuby::ProjectConfig.public_dir
    set :static, true
    register Sinatra::MultiRoute
    route :head, :get, :post, :put, :patch, :delete, '/*' do
      request_uuid = SecureRandom.uuid
      splat = params['splat'][0]
      function_name = resolve_function_name(splat)
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
      context = Oj.dump(FaaStRuby::ProjectConfig.secrets_for_function(function_name))
      event = FaaStRuby::Event.new(body: body, query_params: query_params, headers: headers, context: context)
      log_request_message(function_name, request, request_uuid, query_params, body, context)
      time, response = FaaStRuby::Runner.new(function_name).call(event, rpc_args)
      status response.status
      headers set_response_headers(response, request_uuid, original_request_id, time)
      response_body, print_body = parse_response(response)
      log_response_message(function_name, time, request_uuid, response, print_body)
      body response_body
    end

    def log_request_message(function_name, request, request_uuid, query_params, body, context)
      puts "[#{function_name}] <- [REQUEST: #{request.request_method} \"#{request.fullpath}\"] request_id=\"#{request_uuid}\" body=\"#{body}\" query_params=#{query_params} headers=#{headers}"
    end

    def log_response_message(function_name, time, request_uuid, response, print_body)
      puts "[#{function_name}] -> [RESPONSE: #{time}ms] request_id=\"#{request_uuid}\" status=#{response.status} body=#{print_body.inspect} headers=#{response.headers}"
    end

    def set_response_headers(response, request_uuid, original_request_id = nil, time)
      response.headers['X-Request-Id'] = request_uuid
      response.headers['X-Original-Request-Id'] = original_request_id if original_request_id
      response.headers['X-Execution-time'] = "#{time}ms"
      response.headers
    end

    def parse_response(response)
      return [Base64.urlsafe_decode64(response.body), "Base64(#{response.body[0..70]}...)"] if response.binary?
      return [response.body, "#{response.body[0..70]}..."]
    end

    def resolve_function_name(splat)
      if splat == ''
        puts "Loading root function #{FaaStRuby::ProjectConfig.root_to}"
        return FaaStRuby::ProjectConfig.root_to
      end
      if !is_a_function?(splat)
        puts "#{splat} is not a function. Returning #{FaaStRuby::ProjectConfig.catch_all}"
        return FaaStRuby::ProjectConfig.catch_all
      end
      return splat
    end

    def is_a_function?(name)
      File.file?("#{FaaStRuby::ProjectConfig.functions_dir}/#{name}/faastruby.yml")
    end

    def parse_body(body, content_type, method)
      return nil if method == 'GET'
      return {} if body.nil? && method != 'GET'
      return Oj.load(body) if content_type == 'application/json'
      return body
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