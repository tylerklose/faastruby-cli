module FaaStRuby
  class EventHub
    extend FaaStRuby::Logger::System
    @@queue = Queue.new
    def self.queue
      @@queue
    end

    def self.push(payload)
      @@queue << payload
    end

    def self.thread
      @@thread
    end

    def self.load_subscribers
      Dir.glob('*/*/faastruby.yml').each do |file|
        workspace_name, function_name, _ = file.split('/')
        path = "#{workspace_name}/#{function_name}"
        config = YAML.load(File.read(file))
        next unless config['channels'].is_a?(Array)
        config['channels'].compact!
        config['channels'].each do |c|
          channel = EventChannel.new(c)
          channel.subscribe(path)
        end
      end
      puts "#{tag} Channel subscriptions: #{EventChannel.channels}"
      puts "#{tag} If you modify 'faastruby.yml' in any function, you will need to restart the server to apply the changes."
    end

    def self.listen_for_events!
      load_subscribers
      @@thread = Thread.new do
        loop do
          encoded_channel, encoded_data = @@queue.pop.split(',')
          channel = EventChannel.new(Base64.urlsafe_decode64(encoded_channel))
          puts "#{tag} Event channel=#{channel.name.inspect}"
          channel.subscribers.each do |s|
            subscriber = Subscriber.new(s)
            puts "#{tag} Trigger function=#{subscriber.path.inspect} base64_payload=#{encoded_data.inspect}"
            response = subscriber.call(encoded_data)
            puts "[#{subscriber.path}] #=> status=#{response.status} body=#{response.body.inspect} headers=#{Oj.dump response.headers}".light_blue
          end
        end
      end
      puts "#{tag} Events thread started."
    end
  end
end