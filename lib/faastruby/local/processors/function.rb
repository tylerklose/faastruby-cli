module FaaStRuby
  module Local
    class FunctionProcessor < Processor

      def should_ignore?(event)
        debug "should_ignore?(#{event.inspect})"
        if present_in_ignore_list?(event.dirname)
          debug "SKIP #{event}"
          return true
        end
        if is_a_crystal_function?(event.dirname) && is_crystal_handler_binary?(event.filename)
          debug "ignoring #{event.filename}"
          return true
        end
        return false
      end

      def is_crystal_handler_binary?(filename)
        debug "is_crystal_handler_binary?(#{filename.inspect})"
        filename == 'handler' || filename == 'handler.dwarf'
      end

      def is_a_crystal_function?(directory)
        debug "is_a_crystal_function?(#{directory.inspect})"
        File.file?("#{directory}/handler.cr") || File.file?("#{directory}/src/handler.cr")
      end

      def added(event)
        debug "added(#{event.inspect})"
        # This should trigger
        # - Initialize function
        # - Deploy
        if event.function_created?
          debug "added: a handler file was added"
          return new_function(event)
        end
        unless event.file_is_a_function_config?
          debug "added: a file was added"
          deploy(event)
        end
      end

      def modified(event)
        debug "modified(#{event.inspect})"
        # This should trigger
        # - Compile
        # - Deploy
        compile_function(event)
        deploy(event)
      end

      def removed(event)
        debug "removed(#{event.inspect})"
        # This should trigger
        # - Compile
        # - Deploy
        # - Remove from workspace
        if event.file_is_a_function_config?
          debug "removed: the file is a function_config"
          function_name = event.relative_path
          puts "Function '#{function_name}' was removed."
          return remove_from_workspace(event)
        end
        if !event.file_is_a_handler?
          debug "removed: the file is NOT a function config"
          compile_function(event)
          deploy(event)
          return true
        end
      rescue FaaStRuby::Local::MissingConfigurationFileError
        nil
      end

      def compile_function(event)
        debug "compile_function(#{event.inspect})"
        # This should run if:
        # - Modified any file
        # - Removed any file but handler
        # - Language is cristal
        function = Local::Function.that_has_file(event.full_path, event.type)
        if function.is_a?(Local::CrystalFunction)
          run(function.name, 'compile') do
            debug "+ IGNORE #{function.absolute_folder}"
            add_ignore(function.absolute_folder)
            function.compile
            debug "- IGNORE #{function.absolute_folder}"
            remove_ignore(function.absolute_folder)
          end
        end
      end

      def new_function(event)
        debug "new_function(#{event.inspect})"
        # This should run if:
        # - Handler file is added to a folder
        object = function_object_for_handler(event.filename)
        function = object.new(
          absolute_folder: event.dirname,
          name: File.dirname(event.relative_path),
        )
        run(function.name, 'new_function') do
          debug "+ IGNORE #{event.dirname}"
          add_ignore(event.dirname)
          function.initialize_new_function
          # Needs improvement. We need to wait a bit so it won't try
          # to deploy or compile newly added functions
          sleep 1.5
          debug "- IGNORE #{event.dirname}"
          remove_ignore(event.dirname)
        end
      end

      def function_object_for_handler(filename)
        debug "function_object_for_handler(#{filename.inspect})"
        case filename
        when 'handler.rb'
          Local::RubyFunction
        when 'handler.cr'
          Local::CrystalFunction
        end
      end

      def deploy(event)
        debug "deploy(#{event.inspect})"
        return false unless SYNC_ENABLED
        # This should run when sync is enabled and:
        # - added any file but handler
        # - modified any file
        # - removed any file but handler
        function = Local::Function.that_has_file(event.full_path, event.type)
        run(function.name, 'deploy') do
          debug "+ IGNORE #{function.absolute_folder}"
            add_ignore(function.absolute_folder)
            function.deploy
            debug "- IGNORE #{function.absolute_folder}"
            remove_ignore(function.absolute_folder)
        end
      end

      def remove_from_workspace(event)
        debug "remove_from_workspace(#{event.inspect})"
        return false unless SYNC_ENABLED
        # This should run when sync is enabled and:
        # - removed handler
        function = Local::Function.that_has_file(event.full_path, event.type)
        run(function.name, 'remove_from_workspace') {function.remove_from_workspace}
      end

    end
  end
end