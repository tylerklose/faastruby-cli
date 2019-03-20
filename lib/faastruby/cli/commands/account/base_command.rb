module FaaStRuby
  module Command
    module Account
      PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,50}$/
      EMAIL_REGEX = /\A[a-z0-9\-\.+]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      require 'faastruby/user'
      require 'faastruby/cli/new_credentials'
      class AccountBaseCommand < BaseCommand
      end
    end
  end
end