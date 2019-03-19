require 'oj'
require 'faastruby-rpc'
require 'base64'
require 'sinatra'
require 'sinatra/multi_route'
require 'securerandom'
require 'rouge'
require 'colorize'

module FaaStRuby
  class Server < Sinatra::Base
    include FaaStRuby::Logger::Requests
    set :show_exceptions, true
    set :logging, true
    set :root, SERVER_ROOT
    set :public_folder, FaaStRuby::ProjectConfig.public_dir
    set :static, true
    set :static_cache_control, [:must_revalidate, :proxy_revalidate, :max_age => 0]
    register Sinatra::MultiRoute
    before do
      cache_control :must_revalidate, :proxy_revalidate, :max_age => 0
    end
    route :head, :get, :post, :put, :patch, :delete, '/*' do
      request_uuid = SecureRandom.uuid
      splat = params['splat'][0]
      function_name = resolve_function_name(splat)
      request_headers = parse_headers(env)
      if request_headers.has_key?('Faastruby-Rpc')
        body = nil
        rpc_args = parse_body(request.body.read, request_headers['Content-Type'], request.request_method, true) || []

      else
        body = parse_body(request.body.read, request_headers['Content-Type'], request.request_method)
        rpc_args = []
      end
      request_headers['X-Request-Id'] = request_uuid
      request_headers['Request-Method'] = request.request_method
      original_request_id = request_headers['X-Original-Request-Id']
      query_params = parse_query(request.query_string)
      context = Oj.dump(FaaStRuby::ProjectConfig.secrets_for_function(function_name))
      event = FaaStRuby::Event.new(body: body, query_params: query_params, headers: request_headers, context: context)
      log_request_message(function_name, request, request_uuid, query_params, body || rpc_args, context, request_headers)
      time, response = FaaStRuby::Runner.new(function_name).call(event, rpc_args)
      status response.status
      headers set_response_headers(response, request_uuid, original_request_id, time)
      response_body, print_body = parse_response(response)
      log_response_message(function_name, time, request_uuid, response, print_body)
      body response_body
    end

    def log_request_message(function_name, request, request_uuid, query_params, body, context, request_headers)
      puts "[#{function_name}] <- [REQUEST: #{request.request_method} \"#{request.fullpath}\"] request_id=\"#{request_uuid}\" body=\"#{body}\" query_params=#{query_params} headers=#{request_headers}"
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
      return [Base64.urlsafe_decode64(response.body), "Base64(#{response.body})"] if response.binary?
      return [response.body, "#{response.body}"]
    end

    def resolve_function_name(splat)
      if splat == ''
        return FaaStRuby::ProjectConfig.root_to
      end
      if !is_a_function?(splat)
        return FaaStRuby::ProjectConfig.catch_all
      end
      return splat
    end

    def is_a_function?(name)
      File.file?("#{FaaStRuby::ProjectConfig.functions_dir}/#{name}/faastruby.yml")
    end

    def parse_body(body, content_type, method, rpc=false)
      return nil if method == 'GET'
      return {} if body.nil? && method != 'GET'
      if rpc
        return Oj.load(body, symbol_keys: true) if content_type == 'application/json'
      else
        return Oj.load(body) if content_type == 'application/json'
      end
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
      result = {}
      env.select{|e| e.match(/^HTTP_/)}.each do |k, v|
        newkey = k.sub(/^HTTP_/, '').split('_').map{|x| x.capitalize}.join('-')
        result[newkey] = v
      end
      result['Content-Type'] = env['CONTENT_TYPE']
      result['Request-Method'] = env['REQUEST_METHOD']
      result['Content-Length'] = env['CONTENT_LENGTH']
      result['Remote-Addr'] = env['REMOTE_ADDR']
      result
    end
  end
end