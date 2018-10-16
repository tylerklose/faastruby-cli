module FaaStRuby
  class Workspace < BaseObject

    ##### Class methods
    def self.create(name:, email: nil)
      api = API.new
      workspace = Workspace.new(name: name, email: email, errors: [])
      response = api.create_workspace(workspace_name: name, email: email)
      if response.errors.any?
        workspace.errors += response.errors
        return workspace
      end
      case response.code
      when 422
        workspace.errors += ['(422) Unprocessable Entity', response.body]
      when 200, 201
        workspace.credentials = response.body['credentials']
      else
        workspace.errors << "(#{response.code}) Error"
      end
      return workspace
    end
    ###################

    ##### Instance methods
    attr_accessor :name, :errors, :functions, :email, :object, :credentials

    def destroy
      response = @api.destroy_workspace(@name)
      @errors += response.errors if response.errors.any?
    end

    def deploy(package_file_name)
      response = @api.deploy(workspace_name: @name, package: package_file_name)
      @errors += response.errors if response.errors.any?
      self
    end

    def fetch
      response = @api.get_workspace_info(@name)
      if response.errors.any?
        @errors += response.errors
      else
        self.assign_attributes(response.body)
      end
      self
    end
  end
end