module FaaStRuby
  module Local
    class StaticFile
      include Local::Logger

      def self.full_sync
        cmd = "faastruby deploy-to '#{Local.workspace}' -f '#{Local.public_dir}'"
        output, status = Open3.capture2e(cmd)
        String.disable_colorization = true
        if status.exitstatus == 0
          output.split("\n").each {|o| puts "#{Time.now} | #{o}" unless o == '---'}
          puts '---'
        else
          STDERR.puts output
        end
        String.disable_colorization = false
      end

      def initialize(full_path:, relative_path:, filename:, dirname:)
        @full_path = full_path
        @relative_path = relative_path
        @filename = filename
        @dirname = dirname
        @config = YAML.load(File.read("#{Local.public_dir}/faastruby.yml"))
        @before_build = @config['before_build'] || []
      end

      def deploy
        path = "public/#{@relative_path}"
        cmd = "faastruby cp '#{path}' '#{Local.workspace}:/#{@relative_path}'"
        puts "Running: #{cmd}"
        i, oe, thr = Open3.popen2(cmd)
        i.close
        STDOUT.puts "#{Time.now} | * [#{path}] Uploading file to workspace '#{Local.workspace}'"
        oe.each_line do |line|
          next if line.chomp == '' || line.chomp == '---'
          STDOUT.puts "#{Time.now} | #{line}"
          STDOUT.puts "---"
        end
        thr.join
        oe.close
        status = thr.value
        puts "* [#{path}] Error uploading static file '#{path}' to cloud workspace '#{Local.workspace}':" if status.exitstatus != 0
      end

      def remove_from_workspace
        path = "public/#{@relative_path}"
        cmd = "faastruby rm '#{Local.workspace}:/#{@relative_path}'"
        puts "Running: #{cmd}"
        output, status = Open3.capture2e(cmd)
        String.disable_colorization = true
        if status.exitstatus == 0
          output.split("\n").each {|o| puts o unless o == '---'}
        else
          puts "* [#{path}] Error removing static file '#{path}' from cloud workspace '#{Local.workspace}':"
          STDERR.puts output
        end
        String.disable_colorization = false
      end
    end
  end
end