module FaaStRuby
  class EventHub
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
      puts "#{Time.now} [EventHub] Channel subscriptions: #{EventChannel.channels}".yellow
      puts "#{Time.now} [EventHub] If you modify 'faastruby.yml' in any function, you will need to restart the server to apply the changes.".yellow 
    end

    def self.listen_for_events!
      load_subscribers
      @@thread = Thread.new do
        loop do
          encoded_channel, encoded_data = @@queue.pop.split(',')
          channel = EventChannel.new(Base64.urlsafe_decode64(encoded_channel))
          puts "#{Time.now} [EventHub] Event channel=#{channel.name.inspect}".yellow
          channel.subscribers.each do |s|
            subscriber = Subscriber.new(s)
            puts "#{Time.now} [EventHub] Trigger function=#{subscriber.path.inspect} base64_payload=#{encoded_data.inspect}".yellow
            response = subscriber.call(encoded_data)
            puts "#{Time.now} [#{subscriber.path}] #=> status=#{response.status} body=#{response.body.inspect} headers=#{Oj.dump response.headers}".light_blue
          end
        end
      end
      puts "#{Time.now} [EventHub] Events thread started.".yellow
    end
  end
end