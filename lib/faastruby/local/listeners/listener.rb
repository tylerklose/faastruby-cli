module FaaStRuby
  module Local
    class Listener
      def self.functions_listener
        @@functions_listener ||= []
      end
      def self.public_listener
        @@public_listener ||= []
      end
      def self.opal_listener
        @@opal_listener ||= []
      end

      include Local::Logger
      attr_accessor :listener, :directory, :queue
      def initialize(directory:, queue:)
        debug "initialize(directory: #{directory.inspect}, queue: #{queue.inspect})"
        @directory = directory
        @queue = queue
        @listener = ::Listen.to(directory, &callback)
      end

      def start
        debug "start"
        listener.start
      end

      def stop
        debug "stop"
        listener.stop
      end

      def callback
        debug "callback"
        Proc.new do |modified, added, removed|
          begin
            modified.each do |file|
              queue.push ListenerEvent.new(type: :modified, full_path: file, listened_directory: @directory)
            end
            added.each do |file|
              queue.push ListenerEvent.new(type: :added, full_path: file, listened_directory: @directory)
            end
            removed.each do |file|
              queue.push ListenerEvent.new(type: :removed, full_path: file, listened_directory: @directory)
            end
          rescue StandardError => e
            String.disable_colorization = true
            STDOUT.puts e.full_message
            String.disable_colorization = false
            next
          end
        end
      end
    end

    class ListenerEvent
      include Local::Logger
      attr_accessor :type, :filename, :full_path, :relative_path, :relative_path_dirname, :listened_directory, :dirname
      def initialize(type:, full_path:, listened_directory:)
        debug "initialize(type: #{type.inspect}, full_path: #{full_path.inspect}, listened_directory: #{listened_directory.inspect})"
        @listened_directory = listened_directory
        @full_path = full_path
        @relative_path = relative_path_for(@full_path.dup)
        @relative_path_dirname = File.dirname(@relative_path)
        @filename = File.basename(@full_path)
        @dirname = File.dirname(@full_path)
        @type = type

        debug "EVENT: #{@type}"
        debug "EVENT: #{@full_path}"
      end

      def to_h
        {
          listened_directory: @listened_directory,
          full_path: @full_path,
          relative_path: @relative_path,
          relative_path_dirname: @relative_path_dirname,
          filename: @filename,
          dirname: @dirname,
          type: @type
        }
      end

      def function_created?
        debug __method__
        added? && filename.match(/^handler\.(rb|cr)$/)
      end

      def file_is_a_gemfile?
        debug __method__
        filename == 'Gemfile'
      end

      def file_is_a_gemfile_lock?
        debug __method__
        filename == 'Gemfile.lock'
      end

      def file_is_a_handler?
        debug __method__
        filename.match(/^handler\.(rb|cr)$/)
      end

      def file_is_a_function_config?
        debug __method__
        filename == 'faastruby.yml'
      end

      def file_is_opal_main?
        filename == 'main.rb'
      end

      # def file_was_just_added?
      #   debug __method__
      #   Time.now.to_i - File.ctime(@full_path).to_i <= 1
      # end

      def added?
        debug __method__
        @type == :added
      end

      def modified?
        debug __method__
        @type == :modified
      end

      def removed?
        debug __method__
        @type == :removed
      end

      def relative_path_for(full_path)
        debug "relative_path_for(#{full_path.inspect})"
        full_path.slice!("#{@listened_directory}/")
        full_path
      end
    end
  end
end