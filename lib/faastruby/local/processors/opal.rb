module FaaStRuby
  module Local
    class OpalProcessor < Processor

      def added(event)
        debug "added(#{event.inspect})"
        # does nothing
        return true
      end

      def modified(event)
        debug "modified(#{event.inspect})"
        # This should trigger
        # - compile to JS
        compile(event)
      end

      def removed(event)
        debug "removed(#{event.inspect})"
        # This should trigger
        # - Remove from workspace
        if event.file_is_opal_main?
          remove_from_public(event)
        else
          compile(event)
        end
      end

      def remove_from_public(event)
        delete_path = event.relative_path_dirname.sub(/^#{Local.opal_dir}\//, "#{Local.public_dir}/")
        # return false unless delete_path.match(/^#{Local.public_dir}\//)
        return false if delete_path.nil? || delete_path.match(/^\s*$/)
        puts "Deleting: #{Local.opal_js_destination}/#{delete_path}"
        FileUtils.rm_rf("#{Local.opal_js_destination}/#{delete_path}")
        dir = "#{Local.opal_js_destination}/#{delete_path}"
        delete_recursive_folder(dir)
      end

      def delete_recursive_folder(entry)
        dirname = File.dirname(entry)
        return if dirname == Local.opal_js_destination
        glob = Dir.glob("#{dirname}/*")
        return if glob.any?
        puts "Deleting: #{dirname}"
        FileUtils.rmdir(dirname)
        delete_recursive_folder(dirname)
      end

      def compile(event)
        debug "compile"
        js_path = event.relative_path_dirname.sub(/^#{Local.opal_dir}\//, "")
        FileUtils.mkdir_p("#{Local.opal_js_destination}/#{js_path}")
        compile_cmd = [
          "opal",
          "-I",
          "#{event.dirname}",
          "--gem",
          'jquery',
          "--gem",
          'opal-jquery',
          "--compile",
          "#{event.dirname}/main.rb",
          ">",
          "#{Local.opal_js_destination}/#{js_path}/main.js"
        ]
        # run it:
        run(event.dirname, 'compile') {`#{compile_cmd.join(' ')}`; puts "Done"}
        puts "Running: #{compile_cmd.join(' ')}"
      end

      def first_parent_of(entry, event_type)
        debug "first_parent_of(#{entry.inspect})"
        absolute_folder = get_parent_folder_for(entry)
        if event_type == :removed
          name = absolute_folder.dup
          name.slice!("#{Local.opal_dir}/")
        end
        absolute_folder
      end

      def get_parent_folder_for(entry)
        return File.dirname(entry) if File.basename(entry) == 'main.rb'
        debug "get_parent_folder_for(#{entry.inspect})"
        dirname = File.dirname(entry)
        raise MissingConfigurationFileError.new("ERROR: Could not determine the parent. Make sure your opal folders a main file 'main.rb'.") if dirname == SERVER_ROOT
        return dirname if File.file?("#{dirname}/main.rb")
        get_parent_folder_for(dirname)
      end

    end
  end
end