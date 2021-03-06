module FaaStRuby
  module Local
    class RubyFunction < Function
      include Local::Logger

      def self.default_gemfile
        faastruby_rpc_version = Gem::DependencyList.from_specs.select{|d| d.name == 'faastruby-rpc'}[0]&.version || '0.2.3'
        %(source 'https://rubygems.org'

group :test do
  gem 'rspec'
end
)
      end

      def yaml_hash
        debug "yaml_hash"
        hash = {
          'cli_version' => FaaStRuby::VERSION,
          'name' => @name,
          'runtime' => DEFAULT_RUBY_RUNTIME
        }
      end

      def write_handler
        debug "write_handler"
        content = "def handler(event)\n  # Write code here\n  \nend"
        file = "#{@absolute_folder}/handler.rb"
        if File.size(file) > 0
          puts "New Ruby function '#{@name}' detected."
        else
          File.write(file, content)
          puts "New Ruby function '#{@name}' initialized."
        end
      end
    end
  end
end