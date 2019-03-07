module FaaStRuby
  module Local
    STDOUT_MUTEX = Mutex.new
    module Logger
      def self.puts(msg)
        STDOUT_MUTEX.synchronize do
          STDOUT.puts "#{Time.now} | #{msg}".yellow
          STDOUT.puts "---".yellow
        end
      end

      def debug(msg)
        return false unless DEBUG
        name = self.name if ['Module', 'Class'].include? self.class.name
        name ||= self.class.name
        STDOUT_MUTEX.synchronize do
          STDOUT.puts "#{Time.now} | [DEBUG] [#{name}] #{msg}".red
          STDOUT.puts "---".red
        end
      end

      def puts(msg)
        STDOUT_MUTEX.synchronize do
          STDOUT.puts "#{Time.now} | #{msg}".yellow
          STDOUT.puts "---".yellow
        end
      end

      def print(msg)
        STDOUT_MUTEX.synchronize do
          STDOUT.print "#{Time.now} | #{msg}".yellow
        end
      end

    end
  end
end