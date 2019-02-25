require 'faastruby/api'

module FaaStRuby
  class Workspace < BaseObject

    ##### Class methods
    def self.create(name:, email: nil, provider: nil)
      api = API.new
      workspace = Workspace.new(name: name, email: email, errors: [], provider: provider)
      response = api.create_workspace(workspace_name: name, email: email, provider: provider)
      workspace.status_code = response.code
      if response.errors.any?
        workspace.errors += response.errors
        return workspace
      end
      case response.code
      when 422
        workspace.errors += ['(422) Unprocessable Entity', response.body]
      when 200, 201
        workspace.credentials = response.body['credentials']
        workspace.runners_max = response.body['runners_max'].to_i if response.body['runners_max']
      else
        workspace.errors << "(#{response.code}) Error"
      end
      return workspace
    end
    ###################

    ##### Instance methods
    attr_accessor :name, :errors, :functions, :email, :object, :credentials, :updated_at, :created_at, :status_code, :provider, :runners_max, :runners_current, :static_metadata

    def destroy
      response = @api.destroy_workspace(@name)
      @status_code = response.code
      @errors += response.errors if response.errors.any?
    end

    def deploy(package_file_name, root_to: false, catch_all: false, context: false)
      response = @api.deploy(workspace_name: @name, package: package_file_name, root_to: root_to, catch_all: catch_all, context: context)
      @status_code = response.code
      @errors += response.errors if response.errors.any?
      self
    end

    def refresh_credentials
      response = @api.refresh_credentials(@name)
      @status_code = response.code
      @credentials = response.body[@name] unless response.body.nil?
      @errors += response.errors if response.errors.any?
      self
    end

    def update_runners(value)
      response = @api.update_runners(workspace_name: @name, runners_max: value)
      @runners_max = response.body['runners_max'].to_i if response.body['runners_max'] rescue nil
      @status_code = response.code
      @errors += response.errors if response.errors.any?
      self
    end

    def fetch
      response = @api.get_workspace_info(@name)
      @status_code = response.code
      if response.errors.any?
        @errors += response.errors
      else
        parse_attributes(response.body)
      end
      self
    end

    def static_metadata
      response = @api.get_static_metadata(@name)
      @status_code = response.code
      @errors += response.errors if response.errors.any?
      @static_metadata = response.body['metadata']
      self
    end

    def parse_attributes(attributes)
      @functions = attributes['functions']
      @email = attributes['email']
      @object = attributes['object']
      @updated_at = attributes['updated_at']
      @created_at = attributes['created_at']
      @provider = attributes['provider']
      @runners_max = attributes['runners_max'].to_i if attributes['runners_max'] rescue nil
      @runners_current = attributes['runners_current'].to_i rescue nil
    end
  end
end