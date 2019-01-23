module FaaStRuby
  class EventChannel
    @@channels = {}
    def self.channels
      @@channels
    end
    attr_accessor :name
    def initialize(channel)
      @name = channel
      @@channels[channel] ||= []
    end
    def subscribe(function_path)
      @@channels[@name] << function_path
    end
    def subscribers
      @@channels[@name] || []
    end
  end
end