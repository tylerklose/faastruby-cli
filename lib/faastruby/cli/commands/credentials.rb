module FaaStRuby
  module Command
    module Credentials
      class CredentialsBaseCommand < BaseCommand
      end
    end
  end
end

require 'faastruby/cli/commands/credentials/add'
require 'faastruby/cli/commands/credentials/list'