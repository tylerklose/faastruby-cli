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
      expect(workspace.status_code).to eq(200)
    end

    it '422 response populate errors array' do
      @api.stub_create_workspace(name: @workspace_name, status: 422)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.errors).not_to be_empty
      expect(workspace.status_code).to eq(422)
    end

    it '409 response populate errors array' do
      @api.stub_create_workspace(name: @workspace_name, status: 409)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name)
      expect(workspace.errors).not_to be_empty
      expect(workspace.status_code).to eq(409)
    end

    it 'takes an email' do
      email = 'test@example.com'
      @api.stub_create_workspace(name: @workspace_name, email: email)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name, email: email)
      expect(workspace.email).to eq(email)
    end

    it 'takes a provider' do
      provider = 'example-provider'
      @api.stub_create_workspace(name: @workspace_name, provider: provider)
      workspace = FaaStRuby::Workspace.create(name: @workspace_name, provider: provider)
      expect(workspace.provider).to eq(provider)
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

      it 'sets the status code' do
        @api.stub_destroy_workspace(name: @workspace.name)
        @workspace.destroy
        expect(@workspace.status_code).to eq(200)
      end
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

      it 'sets the status code' do
        @api.stub_deploy_workspace(name: @workspace.name)
        @workspace.deploy(@file.path)
        expect(@workspace.status_code).to eq(200)
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

      it 'fail' do
        @api.stub_deploy_workspace(name: @workspace.name, status: 422)
        @workspace.deploy(@file.path)
        expect(@workspace.errors).not_to be_empty
      end
    end

    describe '#update_runners' do
      before do
        @runners_max = 5
      end

      it 'sets the number of runners' do
        @api.stub_update_runners(name: @workspace.name, runners_max: @runners_max)
        @workspace.update_runners(@runners_max)
        expect(@workspace.runners_max).to eq(@runners_max)
      end

      it 'returns self' do
        @api.stub_update_runners(name: @workspace.name, runners_max: @runners_max)
        expect(@workspace.update_runners(@runners_max)).to eq(@workspace)
      end
      it 'success' do
        @api.stub_update_runners(name: @workspace.name, runners_max: @runners_max)
        @workspace.update_runners(@runners_max)
        expect(@workspace.errors).to be_empty
      end

      it 'fail' do
        @api.stub_update_runners(name: @workspace.name, runners_max: @runners_max, status: 422)
        @workspace.update_runners(@runners_max)
        expect(@workspace.errors).not_to be_empty
      end
    end

    describe '#fetch' do
      it 'sets the status code' do
        @api.stub_get_workspace(name: @workspace.name)
        @workspace.fetch
        expect(@workspace.status_code).to eq(200)
      end
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

    describe '#parse_attributes' do
      it 'sets the object attributes' do
        attributes = {'functions' => ['a'], 'email' => 'email', 'object' => 'obj', 'updated_at' => 'date', 'created_at' => 'date', 'provider' => 'example-provider'}
        @workspace.parse_attributes(attributes)
        expect(@workspace.functions).to eq(attributes['functions'])
        expect(@workspace.email).to eq(attributes['email'])
        expect(@workspace.object).to eq(attributes['object'])
        expect(@workspace.updated_at).to eq(attributes['updated_at'])
        expect(@workspace.created_at).to eq(attributes['created_at'])
        expect(@workspace.provider).to eq(attributes['provider'])
      end
    end

    describe '#refresh_credentials' do
      before do
        @api.stub_refresh_credentials(name: @workspace.name)
      end
      it 'sets the status code' do
        @workspace.refresh_credentials
        expect(@workspace.status_code).to eq(200)
      end
      it 'returns self' do
        expect(@workspace.refresh_credentials).to eq(@workspace)
      end

      it 'success' do
        @workspace.refresh_credentials
        expect(@workspace.errors).to be_empty
        expect(@workspace.credentials).to eq(FaaStRuby::Tests::API.new.credentials_example)
      end

      it 'fail' do
        @api.stub_refresh_credentials(name: @workspace.name, status: 422)
        @workspace.refresh_credentials
        expect(@workspace.errors).not_to be_empty
        expect(@workspace.credentials).to be_nil
      end
    end
  end
end