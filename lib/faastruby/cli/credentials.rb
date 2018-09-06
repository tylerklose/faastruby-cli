module FaaStRuby
  class Credentials # TODO: change it to YAML?
    def self.load_credentials_file
      if File.file?(FAASTRUBY_CREDENTIALS)
        Oj.load(File.read(FAASTRUBY_CREDENTIALS))
      else
        {}
      end
    end

    def self.add(workspace_name, new_credentials, credentials_file)
      credentials = load_credentials_file
      credentials.merge!({workspace_name => new_credentials})
      save_file(credentials, credentials_file)
    end

    def self.remove(workspace_name, credentials_file)
      credentials = load_credentials_file
      credentials.delete_if{|k,v| k == workspace_name}
      save_file(credentials, credentials_file)
    end

    def self.save_file(credentials, credentials_file)
      if File.file?(credentials_file)
        color = :yellow
        symbol = '~'
      else
        color = :green
        symbol = '+'
      end
      File.open(credentials_file, 'w') {|f| f.write Oj.dump(credentials)}
      puts "#{symbol} f #{credentials_file}".colorize(color)
    end

    def self.load_for(workspace_name)
      credentials = load_from_env(workspace_name) || load_credentials_file
      FaaStRuby::CLI.error("Could not find credentials for '#{workspace_name}' in '#{FAASTRUBY_CREDENTIALS}'") unless credentials.has_key?(workspace_name)
      FaaStRuby.configure do |config|
        config.api_key = credentials[workspace_name]['api_key']
        config.api_secret = credentials[workspace_name]['api_secret']
      end
    end

    def self.load_from_env(workspace_name)
      return nil unless ENV['FAASTRUBY_API_KEY'] && ENV['FAASTRUBY_API_SECRET']
      {workspace_name => {'api_key' => ENV['FAASTRUBY_API_KEY'], 'api_secret' => ENV['FAASTRUBY_API_SECRET']}}
    end
  end
end