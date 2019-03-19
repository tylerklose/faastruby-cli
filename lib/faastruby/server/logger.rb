module FaaStRuby
  STDOUT_MUTEX = Mutex.new
  module Logger
    module Requests

      def puts(msg)
        msg = Rouge.highlight(msg, 'ruby', Rouge::Formatters::Terminal256.new(Rouge::Themes::Monokai.new))
        STDOUT_MUTEX.synchronize do
          STDOUT.puts "#{Time.now} | #{msg}"
          STDOUT.puts "---"
        end
      end

      def self.rougify(string, kind)
        Rouge.highlight(string, kind, Rouge::Formatters::Terminal256.new(Rouge::Themes::Monokai.new))
      end

      def rougify(string, kind)
        FaaStRuby::Logger.rougify(string, kind)
      end

      def tag
        return "(#{self.name.split('::').last})" if self.is_a? Class
        return "(#{self.class.name.split('::').last})"
      end

    end

    module System
      def tag
        return "(#{self.name.split('::').last})" if self.is_a? Class
        return "(#{self.class.name.split('::').last})"
      end

      def self.puts(msg)
        STDOUT_MUTEX.synchronize do
          STDOUT.puts "#{Time.now} | #{msg}".yellow
          STDOUT.puts "---".yellow
        end
      end

      def puts(msg)
        STDOUT_MUTEX.synchronize do
          STDOUT.puts "#{Time.now} | #{msg}".yellow
          STDOUT.puts "---".yellow
        end
      end
    end
  end
end