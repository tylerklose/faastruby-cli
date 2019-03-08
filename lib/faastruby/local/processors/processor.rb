module FaaStRuby
  module Local
    class Processor
      include Local::Logger
      attr_accessor :queue, :thread
      def initialize(queue)
        debug "initialize(#{queue.inspect})"
        @queue = queue
        @ignore = {}
        @mutex = Mutex.new
        @threads_mutex = Mutex.new
        @threads = {}
      end

      def start
        debug "start"
        thread = Thread.new do
          loop do
            begin
              event = queue.pop
              next if should_ignore?(event)
              send(event.type, event)
            rescue StandardError => e
              String.disable_colorization = true
              STDOUT.puts e.full_message
              String.disable_colorization = false
              next
            end
          end
        end
      end

      def should_ignore?(event)
        debug "should_ignore?(#{event.inspect})"
        if present_in_ignore_list?(event.dirname)
          debug "SKIP #{event}"
          return true
        end
        return false
      end

      def add_ignore(entry)
        debug "add_ignore(#{entry})"
        @mutex.synchronize do
          @ignore[entry] = true
          debug "Added #{@ignore[entry]}"
        end
      end

      def present_in_ignore_list?(entry)
        debug "present_in_ignore_list(#{entry})"
        @mutex.synchronize do
          @ignore[entry] ? debug(true) : debug(false)
          @ignore[entry]
        end
      end

      def remove_ignore(entry)
        debug "remove_ignore(#{entry})"
        @mutex.synchronize do
          @ignore.delete(entry)
          debug "Removed: is nil? #{@ignore[entry].nil?}"
        end
      end

      def run(name, action, &block)
        debug __method__
        kill_thread(name, action)
        add_thread(name, action, &block)
      end

      def add_thread(name, action, &block)
        debug __method__
        @threads_mutex.synchronize do
          @threads[name] = {action => start_thread(name, action, &block)}
        end
      end

      def start_thread(name, action, &block)
        debug __method__
        Thread.new do
          Thread.report_on_exception = false
          yield
          remove_thread_record(name, action)
        end
      end

      def get_thread(name, action)
        debug __method__
        @threads_mutex.synchronize do
          return
          return nil
        end
      end

      def remove_thread_record(name, action)
        @threads_mutex.synchronize do
          if @threads[name] && @threads[name][action]
            @threads[name].delete(action)
          end
        end
      end

      def kill_thread(name, action)
        debug __method__
        @threads_mutex.synchronize do
          if @threads[name] && @threads[name][action]
            puts "Killing previous '#{action}' action for '#{name}'."
            Thread.kill @threads[name][action]
            @threads[name].delete(action)
          end
        end
      end
    end
  end
end