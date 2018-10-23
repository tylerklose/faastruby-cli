require 'tempfile'
RSpec.describe FaaStRuby::Workspace do
  describe 'Creating workspace' do
    before do
      @workspace_name = 'test-workspace'
      @api = FaaStRuby::Tests::API.new
    end
    it '200 response has no errors' do
      @api.stub_create_workspace(name: @workspace_name)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.errors).to be_empty
    end

    it '422 response populate errors array' do
      @api.stub_create_workspace(name: @workspace_name, status: 422)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.errors).not_to be_empty
    end

    it '409 response populate errors array' do
      @api.stub_create_workspace(name: @workspace_name, status: 409)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.errors).not_to be_empty
    end

    it 'takes an email' do
      email = 'test@example.com'
      @api.stub_create_workspace(name: @workspace_name, email: email)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name, email: email)
      expect(workspace.email).to eq(email)
    end

    it 'email should be optional' do
      @api.stub_create_workspace(name: @workspace_name)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace).to be_instance_of(FaaStRuby::Workspace)
    end

    it 'credentials get set' do
      @api.stub_create_workspace(name: @workspace_name)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.credentials).to eq({'api_secret' => 'API_SECRET','api_key' => 'API_KEY'})
    end

    it 'any other status will throw error' do
      @api.stub_create_workspace(name: @workspace_name, status: 500)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.errors).not_to be_empty
    end
  end
  describe 'Instance methods' do
    before do
      @api = FaaStRuby::Tests::API.new
      @workspace = FaaStRuby::Workspace.new(name: 'test-workspace')
    end

    describe '#destroy' do
      it 'success' do
        @api.stub_destroy_workspace(name: @workspace.name)
        @workspace.destroy
        expect(@workspace.errors).to be_empty
      end

      it 'fail' do
        @api.stub_destroy_workspace(name: @workspace.name, status: 422)
        @workspace.destroy
        expect(@workspace.errors).not_to be_empty
      end
    end

    describe '#deploy' do
      before do
        @file = Tempfile.new('file.zip')
      end
      it 'returns self' do
        @api.stub_deploy_workspace(name: @workspace.name)
        expect(@workspace.deploy(@file.path)).to eq(@workspace)
      end
      it 'success' do
        @api.stub_deploy_workspace(name: @workspace.name)
        @workspace.deploy(@file.path)
        expect(@workspace.errors).to be_empty
      end

      it 'success' do
        @api.stub_deploy_workspace(name: @workspace.name, status: 422)
        @workspace.deploy(@file.path)
        expect(@workspace.errors).not_to be_empty
      end
    end

    describe '#fetch' do
      it 'returns self' do
        @api.stub_get_workspace(name: @workspace.name)
        expect(@workspace.fetch).to eq(@workspace)
      end

      it 'success' do
        @api.stub_get_workspace(name: @workspace.name)
        @workspace.fetch
        expect(@workspace.errors).to be_empty
        expect(@workspace.object).to eq('workspace')
      end

      it 'fail' do
        @api.stub_get_workspace(name: @workspace.name, status: 422)
        @workspace.fetch
        expect(@workspace.errors).not_to be_empty
      end
    end
  end
end