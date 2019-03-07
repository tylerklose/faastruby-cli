module FaaStRuby
  module Local
    class StaticFileProcessor < Processor

      def added(event)
        debug "added(#{event.inspect})"
        # This should trigger
        # - Copy to workspace
        deploy(event)
      end

      def modified(event)
        debug "modified(#{event.inspect})"
        # This should trigger
        # - Copy to workspace
        deploy(event)
      end

      def removed(event)
        debug "removed(#{event.inspect})"
        # This should trigger
        # - Remove from workspace
        remove_from_workspace(event)
      end

      def deploy(event)
        static_file = StaticFile.new(
          full_path: event.full_path,
          relative_path: event.relative_path,
          filename: event.filename,
          dirname: event.dirname
        )
        run(event.relative_path, 'deploy') {static_file.deploy}
      end

      def remove_from_workspace(event)
        static_file = StaticFile.new(
          full_path: event.full_path,
          relative_path: event.relative_path,
          filename: event.filename,
          dirname: event.dirname
        )
        run(event.relative_path, 'remove_from_workspace') {static_file.remove_from_workspace}
      end

    end
  end
end