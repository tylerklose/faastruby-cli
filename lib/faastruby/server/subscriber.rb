module FaaStRuby
  class Subscriber
    attr_accessor :path
    def initialize(path)
      @path = path
      @workspace_name, @function_name = @path.split("/")
    end

    def call(encoded_data)
      data = Base64.urlsafe_decode64(encoded_data)
      headers = {'X-Origin' => 'event_hub', 'Content-Transfer-Encoding' => 'base64'}
      event = Event.new(body: data, query_params: {}, headers: headers, context: nil)
      Runner.new.call(@workspace_name, @function_name, event, [])
    end
  end
end