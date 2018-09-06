module FaaStRuby
  def self.included(base)
    base.extend(SpecHelper)
    $LOAD_PATH << Dir.pwd
  end
  module SpecHelper
    class Event
      @@event = Struct.new(:body, :query_params, :headers, :context)
      def self.new(body: 'example body', query_params: {'foo' => 'bar'}, headers: {'Foo' => 'Bar'}, context: '{"foo": "bar"}')
        @@event.new(body, query_params, headers, context)
      end
    end
    class Response
      @@response = Struct.new(:body, :status, :headers)
      def self.new(body, status, headers)
        @@response.new(body, status, headers)
      end
    end
  end
  def respond_with(body, status: 200, headers: {})
    SpecHelper::Response.new(body, status, headers)
  end
end
