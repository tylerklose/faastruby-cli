module FaaStRuby
  class User
    # TODO: rename ~/.faastruby to ~/.faastruby.tor1 on legacy customers
    def self.credentials_file
      File.expand_path '~/.faastruby/credentials.yml'
    end
  end
end