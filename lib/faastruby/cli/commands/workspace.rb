module FaaStRuby
  module Command
    module Workspace
      class WorkspaceBaseCommand < BaseCommand
      end
    end
  end
end

require 'faastruby/cli/commands/workspace/create'
require 'faastruby/cli/commands/workspace/destroy'
require 'faastruby/cli/commands/workspace/list'
require 'faastruby/cli/commands/workspace/deploy'
