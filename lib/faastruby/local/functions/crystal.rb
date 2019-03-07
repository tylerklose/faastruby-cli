module FaaStRuby
  module Local
    class CrystalFunction < Function
      include Local::Logger
      def compile
        debug "compile"
        handler_path = get_handler_path
        debug "File exists? #{handler_path} - #{File.file?(handler_path)}"
        runtime_path = Pathname.new "#{Gem::Specification.find_by_name("faastruby").gem_dir}/lib/faastruby/local/crystal_runtime.cr"
        h_path = Pathname.new(handler_path)
        handler_path = h_path.relative_path_from runtime_path
        build_cmd = "cd #{@absolute_folder} && crystal build #{runtime_path} -o handler"
        debug "Running #{build_cmd}"
        job_id = SecureRandom.uuid
        puts "Job ID=\"#{job_id}\" started: Compiling function '#{@name}'"
        # return false unless precompile
        env = {'HANDLER_PATH' => handler_path.to_s}
        debug "COMPILE ENV: #{env}"
        output, status = Open3.capture2e(env, build_cmd)
        success = status.exitstatus == 0
        if success
          puts "Job ID=\"#{job_id}\" completed: #{status}"
        else
          puts "Job ID=\"#{job_id}\" failed:"
          String.disable_colorization = true
          STDERR.puts output
          STDOUT.puts '---'
          String.disable_colorization = false
        end
        # puts "Job ID=\"#{job_id}\": #{output}" unless success
        # puts "Job ID=\"#{job_id}\" #{success ? 'completed' : 'failed'}: #{status}"
      end

      def get_handler_path
        if File.file?("#{@absolute_folder}/handler.cr")
          "#{@absolute_folder}/handler"
        else
          "#{@absolute_folder}/src/handler"
        end
      end

      def yaml_hash
        debug "yaml_hash"
        hash = {
          'cli_version' => FaaStRuby::VERSION,
          'name' => @name,
          'runtime' => DEFAULT_CRYSTAL_RUNTIME
        }
      end

      def write_handler
        debug "write_handler"
        content = "def handler(event)\n  # Write code here\n  \nend"
        file = "#{get_handler_path}.cr"
        if File.size(file) > 0
          puts "New Crystal function '#{@name}' detected."
        else
          File.write(file, content)
          puts "New Crystal function '#{@name}' initialized."
        end
      end
    end
  end
end