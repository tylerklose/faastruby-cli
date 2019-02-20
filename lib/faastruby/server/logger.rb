module FaaStRuby
  module Logger
    def self.puts(msg)
      msg = Rouge.highlight(msg, 'ruby', Rouge::Formatters::Terminal256.new(Rouge::Themes::Monokai.new))
      OUTPUT_MUTEX.synchronize do
        STDOUT.puts "#{Time.now} #{msg}"
        STDOUT.puts "---"
      end
    end

    def self.rougify(string, kind)
      Rouge.highlight(string, kind, Rouge::Formatters::Terminal256.new(Rouge::Themes::Monokai.new))
    end

    # def self.tag
    #   "(#{self.name.split('::').last})"
    # end

    def rougify(string, kind)
      FaaStRuby::Logger.rougify(string, kind)
    end

    def tag
      return "(#{self.name.split('::').last})" if self.is_a? Class
      return "(#{self.class.name.split('::').last})"
    end

    def puts(msg)
      FaaStRuby::Logger.puts(msg)
    end
  end
end