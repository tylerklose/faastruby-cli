module FaaStRuby
  class Function < BaseObject
    attr_accessor :name, :workspace, :errors, :context

    def run(options)
      method = options['method'] || 'get'
      headers = options['headers'] || {}
      response = @api.run(function_name: name, workspace_name: options['workspace_name'], payload: options['body'], method: method, headers: headers, time: options['time'], query: options['query'])
      response
    end

    def destroy
      response = @api.delete_from_workspace(function: self, workspace: @workspace)
      @errors += response.errors if response.errors.any?
    end

    def update
      payload = {'context' => context}
      response = @api.update_function_context(function: self, workspace: @workspace, payload: payload)
      @errors += response.errors if response.errors.any?
      unless @errors.any?
        self.context = response.body['context']
      end
      self
    end
  end
end