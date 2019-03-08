module FaaStRuby
  module NewCredentials
    require 'fileutils'
    require 'yaml'
    class CredentialsFile
      def initialize
        @folder = File.expand_path("~/.faastruby")
        @file = "#{@folder}/credentials.yml"
        rename_if_old_file_exists
        create_credentials_folder
      end

      def rename_if_old_file_exists
        old_file = File.expand_path("~/.faastruby")
        return true unless File.file?(old_file)
        new_file = File.expand_path("~/.faastruby.tor1")
        FileUtils.mv(old_file, new_file)
        return true
      end

      def create_credentials_folder
        return true if File.file?(@file)
        FileUtils.mkdir_p(@folder)
      end

      def read
        YAML.load(File.read(@file)) rescue {}
      end

      def get
        creds = read['credentials'] || {}
        unless creds['email'] && creds['api_key'] && creds['api_secret']
          FaaStRuby::CLI.error("Please login and try again.\nTo login, run 'faastruby login'.")
        end
        creds
      end

      def has_user_logged_in?
        creds = read['credentials'] || {}
        creds['email'] && creds['api_key'] && creds['api_secret']
      end

      def save(email:, api_key:, api_secret:)
        yaml = {
          'credentials' => {
            'email' => email,
            'api_key' => api_key,
            'api_secret' => api_secret
          }
        }.to_yaml
        File.write(@file, yaml)
      end

      def clear
        yaml = {
          'credentials' => {}
        }.to_yaml
        File.write(@file, yaml)
      end
    end
  end
end