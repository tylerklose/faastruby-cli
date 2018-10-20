require 'tempfile'
RSpec.describe FaaStRuby::Workspace do
  describe 'Instance methods' do
    before do
      @api = FaaStRuby::Tests::API.new
      @workspace = FaaStRuby::Workspace.new(name: 'test-workspace')
      @function = FaaStRuby::Function.new(name: 'test-function', workspace: @workspace)
      @options = {'workspace_name' => @workspace.name, 'body' => 'Example body'}
      @api.stub_run_function(function_name: @function.name, workspace_name: @workspace.name, method: :get)
      @url_path = "#{FAASTRUBY_HOST}/#{@workspace.name}/#{@function.name}"
    end

    describe '#run(options)' do
      it 'method defaults to get' do
        @function.run(@options)
        expect(WebMock).to have_requested(:get, @url_path)
      end

      it 'chosen method is respected' do
        @api.stub_run_function(function_name: @function.name, workspace_name: @workspace.name, method: :post)
        @options['method'] = 'post'
        @function.run(@options)
        expect(WebMock).to have_requested(:post, @url_path)
      end

      it 'headers default to {}' do
        @function.run(@options)
        expect(@options['headers']).to eq({})
      end

      it 'headers get passed' do
        @options['headers'] = {'Custom' => 'Header'}
        @function.run(@options)
        expect(WebMock).to have_requested(:get, @url_path).with(headers: @options['headers'])
      end

      it 'returns a response object with a body attribute' do
        response = @function.run(@options)
        expect(response.body).to eq('Function response')
      end
    end

    describe '#destroy' do
      it 'success' do
        @api.stub_delete_from_workspace(function_name: @function.name, workspace_name: @workspace.name)
        @function.destroy
        expect(@function.errors).to be_empty
      end

      it 'fail' do
        @api.stub_delete_from_workspace(function_name: @function.name, workspace_name: @workspace.name, status: 422)
        @function.destroy
        expect(@function.errors).not_to be_empty
      end
    end

    describe '#update' do
      before do
        @context = {'context' => 'new context data'}
      end
      it 'success updating context' do
        @api.stub_update_function(function_name: @function.name, workspace_name: @workspace.name, context: @context)
        function = @function.update(new_context: @context['context'])
        expect(@function.context).to eq(@context['context'])
        expect(@function.errors).to be_empty
        expect(function).to eq(@function)
      end

      it 'fail updating context' do
        @api.stub_update_function(function_name: @function.name, workspace_name: @workspace.name, status: 422, context: @context)
        function = @function.update(new_context: @context['context'])
        expect(@function.errors).not_to be_empty
        expect(function).to eq(@function)
      end
    end
  end
end