module FaaStRuby
  module Sentinel
    class BaseHandler

      def self.perform(full_path, relative_path, event, listener)
        new(full_path, relative_path, listener).trigger_action(event)
      end

      def log(msg)
        puts "#{Time.now} (Sentinel) #{msg}".yellow
      end

      def trigger_action(event)
        send(event)
      end


      # def self.add_thread(function_folder, key, value)
      #   THREAD_ACCESS.synchronize do
      #     @@threads[function_folder] ||= {}
      #     @@threads[function_folder][key] = value
      #   end
      # end
      # def self.get_thread(function_folder, key)
      #   THREAD_ACCESS.synchronize do
      #     return nil if @@threads[function_folder].nil?
      #     @@threads[function_folder][key]
      #   end
      # end

      # def self.get_threads
      #   MUTEX.synchronize do
      #     @@threads
      #   end
      # end

      # def self.tag
      #   '(Sentinel)'
      # end
    end
  end
end