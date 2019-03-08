# require 'json'
# require 'colorize'
# module FaaStRuby
#   class Credentials # TODO: change it to YAML?
#     def self.load_credentials_file(credentials_file = FaaStRuby.credentials_file)
#       return {} unless File.file?(credentials_file)
#       creds = Oj.load(File.read(credentials_file))
#       if creds.is_a?(Hash)
#         creds.delete_if{|workspace, credentials| credentials.nil?}
#         return creds
#       end
#       return {}
#     end

#     def self.add(workspace_name, new_credentials, credentials_file)
#       FaaStRuby::CLI.error("Error trying to save null credentials. You probably found a bug in the gem. Please report it at https://github.com/FaaStRuby/faastruby-cli/issues/new") unless new_credentials
#       credentials = load_credentials_file(credentials_file)
#       credentials.merge!({workspace_name => new_credentials})
#       save_file(credentials, credentials_file)
#     end

#     def self.remove(workspace_name, credentials_file)
#       credentials = load_credentials_file
#       credentials.delete_if{|k,v| k == workspace_name}
#       save_file(credentials, credentials_file)
#     end

#     def self.save_file(credentials, credentials_file)
#       if File.file?(credentials_file)
#         color = :yellow
#         symbol = '~'
#       else
#         color = :green
#         symbol = '+'
#       end
#       credentials.delete_if{|workspace, creds| creds.nil?}
#       File.open(credentials_file, 'w') {|f| f.write JSON.pretty_generate(credentials)}
#       puts "#{symbol} f #{credentials_file}".colorize(color)
#     end

#     def self.load_for(workspace_name, cred_file = FaaStRuby.credentials_file, exit_on_error: true)
#       credentials = load_from_env(workspace_name) || load_credentials_file(cred_file)
#       error_msg = "Could not find credentials for '#{workspace_name}' in '#{cred_file}'"
#       if exit_on_error && !credentials[workspace_name]
#         FaaStRuby::CLI.error(error_msg)
#       elsif !credentials[workspace_name]
#         puts error_msg
#         return false
#       end
#       FaaStRuby.configure do |config|
#         config.api_key = credentials[workspace_name]['api_key']
#         config.api_secret = credentials[workspace_name]['api_secret']
#       end
#       return true
#     end

#     def self.load_from_env(workspace_name)
#       return nil unless ENV['FAASTRUBY_API_KEY'] && ENV['FAASTRUBY_API_SECRET']
#       puts "#{"WARNING:".red} Using credentials from env vars FAASTRUBY_API_KEY and FAASTRUBY_API_SECRET"
#       {workspace_name => {'api_key' => ENV['FAASTRUBY_API_KEY'], 'api_secret' => ENV['FAASTRUBY_API_SECRET']}}
#     end
#   end
# end
