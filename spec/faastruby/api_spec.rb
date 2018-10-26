require 'tempfile'
require 'ostruct'
RSpec.describe FaaStRuby::API do
  before do
    FaaStRuby.configure do |config|
      config.api_key = 'API_KEY'
      config.api_secret = 'API_SECRET'
    end
    @api = FaaStRuby::API.new
    @fake_api = FaaStRuby::Tests::API.new
  end
  describe '#initialize' do
    it 'sets @api_url, @credentials and @headers' do
      expect(@api.api_url).to eq("#{FAASTRUBY_HOST}/v2")
      expect(@api.credentials).to eq({'API-KEY' => 'API_KEY', 'API-SECRET' => 'API_SECRET'})
      expect(@api.headers).to eq({content_type: 'application/json', accept: 'application/json', 'API-KEY' => 'API_KEY', 'API-SECRET' => 'API_SECRET'})
    end
  end

  describe '#create_workspace' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/v2/workspaces"
      @fake_api.stub_create_workspace(name: 'test-workspace')
      @api_response = @api.create_workspace(workspace_name: 'test-workspace')
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:post, @url_path)
    end
    it 'returns a struct with body, errors and status code' do
      expect(@api_response).to have_attributes(body: @fake_api.create_workspace_response, code: 200, errors: [])
    end
  end

  describe '#destroy_workspace' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/v2/workspaces/test-workspace"
      @fake_api.stub_destroy_workspace(name: 'test-workspace')
      @api_response = @api.destroy_workspace('test-workspace')
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:delete, @url_path)
    end
    it 'returns a struct with body, errors and status code' do
      expect(@api_response).to have_attributes(body: {}, code: 200, errors: [])
    end
  end

  describe '#get_workspace_info' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/v2/workspaces/test-workspace"
      @fake_api.stub_get_workspace(name: 'test-workspace')
      @api_response = @api.get_workspace_info('test-workspace')
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:get, @url_path)
    end
    it 'returns a struct with body, errors and status code' do
      expect(@api_response).to have_attributes(body: @fake_api.get_workspace_response, code: 200, errors: [])
    end
  end

  describe '#refresh_credentials' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/v2/workspaces/test-workspace/credentials"
      @fake_api.stub_refresh_credentials(name: 'test-workspace')
      @api_response = @api.refresh_credentials('test-workspace')
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:put, @url_path)
    end
    it 'returns a struct with body, errors and status code' do
      expect(@api_response).to have_attributes(body: {'test-workspace' => @fake_api.credentials_example}, code: 200, errors: [])
    end
  end

  describe '#deploy' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/v2/workspaces/test-workspace/deploy"
      @fake_api.stub_deploy_workspace(name: 'test-workspace')
      @file = Tempfile.new('file.zip')
      @api_response = @api.deploy(workspace_name: 'test-workspace', package: @file)
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:post, @url_path)
    end
    it 'returns a struct with body, errors and status code' do
      expect(@api_response).to have_attributes(body: {}, code: 200, errors: [])
    end
  end

  describe '#delete_from_workspace' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/v2/workspaces/test-workspace/functions/test-function"
      @fake_api.stub_delete_from_workspace(workspace_name: 'test-workspace', function_name: 'test-function')
      @api_response = @api.delete_from_workspace(workspace_name: 'test-workspace', function_name: 'test-function')
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:delete, @url_path)
    end
    it 'returns a struct with body, errors and status code' do
      expect(@api_response).to have_attributes(body: {}, code: 200, errors: [])
    end
  end

  describe '#run' do
    before do
      @url_path = "#{FAASTRUBY_HOST}/test-workspace/test-function"
      @fake_api.stub_run_function(function_name: 'test-function', workspace_name: 'test-workspace', method: :post, query: '?foo=bar')
      @api_response = @api.run(workspace_name: 'test-workspace', function_name: 'test-function', payload: 'Example function', method: 'post', headers: {'Example' => 'Header'}, query: '?foo=bar')
    end
    it 'makes a request' do
      expect(WebMock).to have_requested(:post, @url_path).with(query: {'foo' => 'bar'})
    end
    it 'returns a rest-client response' do
      expect(@api_response.body).to eq('Function response')
      expect(@api_response.code).to eq(200)
    end

    describe '#update_function_context' do
      before do
        @url_path = "#{FAASTRUBY_HOST}/v2/workspaces/test-workspace/functions/test-function"
        @fake_api.stub_update_function(workspace_name: 'test-workspace', function_name: 'test-function', context: {'context' => 'new context'})
        @api_response = @api.update_function_context(workspace_name: 'test-workspace', function_name: 'test-function', payload: {'context' => 'new context'})
      end
      it 'makes a request' do
        expect(WebMock).to have_requested(:patch, @url_path)
      end
      it 'returns a struct with body, errors and status code' do
        expect(@api_response).to have_attributes(body: @fake_api.function_response('new context'), code: 200, errors: [])
      end
    end

    describe '#parse' do
      before do
        @rest_client_response = OpenStruct.new(body: '{"foo": "bar"}', code: 200)
      end
      it 'returns an object with attributes body, errors and code' do
        expect(@api.parse(@rest_client_response)).to have_attributes(body: {'foo' => 'bar'}, code: 200, errors: [])
      end
      it '401 error' do
        @rest_client_response = OpenStruct.new(body: '{"error": "bar"}', code: 401)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 401, errors: ['(401) Unauthorized - bar'])
      end
      it '404 error' do
        @rest_client_response = OpenStruct.new(body: '{"error": "bar"}', code: 404)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 404, errors: ['(404) Not Found - bar'])
      end
      it '409 error' do
        @rest_client_response = OpenStruct.new(body: '{"error": "bar"}', code: 409)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 409, errors: ['(409) Conflict - bar'])
      end
      it '500 error' do
        @rest_client_response = OpenStruct.new(code: 500)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 500, errors: ['(500) Error'])
      end
      it '408 error' do
        @rest_client_response = OpenStruct.new(code: 408)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 408, errors: ['(408) Request Timeout'])
      end
      it '402 error' do
        @rest_client_response = OpenStruct.new(code: 402, body: '{"error": "bar"}')
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 402, errors: ['(402) Limit Exceeded - bar'])
      end
      it '422 error' do
        @rest_client_response = OpenStruct.new(body: '{"error": "bar", "errors": ["error1", "error2"]}', code: 422)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 422, errors: ['(422) Unprocessable Entity', 'bar', 'error1', 'error2'])
      end
      it '200' do
        @rest_client_response = OpenStruct.new(body: '{"response": "bar"}', code: 200)
        expect(@api.parse(@rest_client_response)).to have_attributes(code: 200, errors: [], body: {'response' => 'bar'})
      end
    end

    describe '#error' do
      it 'returns an object with body, errors and code' do
        object = @api.error(['error'], 123)
        expect(object).to have_attributes(response: nil, body: nil, errors: ['error'], code: 123)
      end
    end

  end
end