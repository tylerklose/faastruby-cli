require 'json'

module FaaStRuby
  module Tests
    class API
      include WebMock::API
      def initialize()
      end

      def create_workspace_response(name = 'test-workspace', email = nil)
        hash = {
          'object' => 'workspace',
          'name' => name,
          'credentials' => {
            'api_secret' => 'API_SECRET',
            'api_key' => 'API_KEY'
          }, 'created_at' => '2018-10-22 19:02:51 +0000',
          'errors' => [],
          'updated_at' => '2018-10-22 19:02:52 +0000'
        }

        hash['email'] = email if email
        hash
      end

      def get_workspace_response(name = 'test-workspace', email = nil)
        hash = create_workspace_response(name, email)
        hash.delete('created_at')
        hash['credentials'].delete('api_secret')
        hash
      end

      def function_response(context)
        {
          'workspace_name' => 'test-workspace',
          'name' => 'test-function',
          'context' => context,
          'dashboard_uid' => 'abcdef'
        }
      end

      def stub_create_workspace(name:, email: nil, status: 200)
        stub_request(:post, "#{FAASTRUBY_HOST}/v2/workspaces").to_return(body: create_workspace_response(name, email).to_json, status: status)
      end

      def stub_destroy_workspace(name:, status: 200)
        stub_request(:delete, "#{FAASTRUBY_HOST}/v2/workspaces/#{name}").to_return(body: '{}', status: status)
      end

      def stub_deploy_workspace(name:, status: 200)
        stub_request(:post, "#{FAASTRUBY_HOST}/v2/workspaces/#{name}/deploy").to_return(body: '{}', status: status)
      end

      def stub_get_workspace(name:, status: 200)
        stub_request(:get, "#{FAASTRUBY_HOST}/v2/workspaces/#{name}").to_return(body: get_workspace_response(name).to_json, status: status)
      end

      def stub_run_function(method:, function_name:, workspace_name:, status: 200, query: nil)
        stub_request(method, "#{FAASTRUBY_HOST}/#{workspace_name}/#{function_name}#{query}").to_return(body: "Function response", status: status)
      end

      def stub_delete_from_workspace(method: :delete, function_name:, workspace_name:, status: 200)
        stub_request(method, "#{FAASTRUBY_HOST}/v2/workspaces/#{workspace_name}/functions/#{function_name}").to_return(body: "{}", status: status)
      end

      def stub_update_function(method: :patch, function_name:, workspace_name:, status: 200, context:)
        stub_request(method, "#{FAASTRUBY_HOST}/v2/workspaces/#{workspace_name}/functions/#{function_name}").with(body: context.to_json).to_return(body: function_response(context['context']).to_json, status: status)
      end
    end
  end
end