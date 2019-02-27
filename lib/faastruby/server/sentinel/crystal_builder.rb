module FaaStRuby
  module Sentinel
    require 'open3'
    class CrystalBuild
      include FaaStRuby::Logger::System
      def initialize(directory, handler_path, run_before_build: false)
        @directory = directory
        @function_name = Sentinel.get_function_name(directory)
        @runtime_path = Pathname.new "#{Gem::Specification.find_by_name("faastruby").gem_dir}/lib/faastruby/server/crystal_runtime.cr"
        h_path = Pathname.new(handler_path)
        @handler_path = h_path.relative_path_from @runtime_path
        @env = {'HANDLER_PATH' => @handler_path.to_s}
        @run_before_build = run_before_build
        @crystal_build = "cd #{@directory} && crystal build #{@runtime_path} -o handler"
      end

      def pre_compile_list
        return [] unless @run_before_build
        YAML.load(File.read("#{@directory}/faastruby.yml"))["before_build"] || []
      end

      def precompile
        pre_compile_list.each do |cmd|
          cmd = "cd #{@directory} && #{cmd}"
          puts "#{tag} Job ID=\"#{job_id}\" running before_build: '#{cmd}'"
          output, status = Open3.capture2e(cmd)
          success = status.exitstatus == 0
          unless success
            puts "#{tag} #{output}"
            puts "#{tag} Job ID=\"#{job_id}\" failed: #{status}"
            return false
          end
        end
        return true
      end

      def start
        Thread.report_on_exception = false
        job_id = SecureRandom.uuid
        puts "#{tag} Job ID=\"#{job_id}\" started: Compiling function '#{@function_name}'"
        return false unless precompile
        output, status = Open3.capture2e(@env, @crystal_build)
        success = status.exitstatus == 0
        puts "#{tag} #{output}" unless success
        puts "#{tag} Job ID=\"#{job_id}\" #{success ? 'completed' : 'failed'}: #{status}"
      end
    end

  end
end