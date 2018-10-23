module FaaStRuby
  class Function < BaseObject
    attr_accessor :name, :workspace, :errors, :context, :updated_at, :created_at

    def run(options)
      options['method'] ||= 'get'
      options['headers'] ||= {}
      response = @api.run(function_name: name, workspace_name: options['workspace_name'], payload: options['body'], method: options['method'], headers: options['headers'], time: options['time'], query: options['query'])
      response
    end

    def destroy
      response = @api.delete_from_workspace(function_name: self.name, workspace_name: @workspace.name)
      @errors += response.errors if response.errors.any?
    end

    def update(new_context:)
      payload = {'context' => new_context}
      response = @api.update_function_context(function_name: self.name, workspace_name: @workspace.name, payload: payload)
      @errors += response.errors if response.errors.any?
      unless @errors.any?
        self.context = response.body['context']
      end
      self
    end
  end
end