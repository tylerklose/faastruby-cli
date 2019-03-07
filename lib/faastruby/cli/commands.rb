module FaaStRuby
  module Command
    require 'faastruby/cli/base_command'
    require 'faastruby/cli/credentials'
    COMMANDS = {
      'new' => Proc.new do
        require 'faastruby/cli/commands/function/new'
        FaaStRuby::Command::Function::New
      end,
      'deploy-to' => Proc.new do
        require 'faastruby/cli/commands/function/deploy_to'
        FaaStRuby::Command::Function::DeployTo
      end,
      'remove-from' => Proc.new do
        require 'faastruby/cli/commands/function/remove_from'
        FaaStRuby::Command::Function::RemoveFrom
      end,
      'update-context' => Proc.new do
        require 'faastruby/cli/commands/function/update_context'
        FaaStRuby::Command::Function::UpdateContext
      end,
      'upgrade' => Proc.new do
        require 'faastruby/cli/commands/function/upgrade'
        FaaStRuby::Command::Function::Upgrade
      end,
      'build' => Proc.new do
        require 'faastruby/cli/commands/function/build'
        FaaStRuby::Command::Function::Build
      end,
      'create-workspace' => Proc.new do
        require 'faastruby/cli/commands/workspace/create'
        FaaStRuby::Command::Workspace::Create
      end,
      'cp' => Proc.new do
        require 'faastruby/cli/commands/workspace/cp'
        FaaStRuby::Command::Workspace::CP
      end,
      'rm' => Proc.new do
        require 'faastruby/cli/commands/workspace/rm'
        FaaStRuby::Command::Workspace::RM
      end,
      'update-workspace' => Proc.new do
        require 'faastruby/cli/commands/workspace/update'
        FaaStRuby::Command::Workspace::Update
      end,
      'destroy-workspace' => Proc.new do
        require 'faastruby/cli/commands/workspace/destroy'
        FaaStRuby::Command::Workspace::Destroy
      end,
      'list-workspace' => Proc.new do
        require 'faastruby/cli/commands/workspace/list'
        FaaStRuby::Command::Workspace::List
      end,
      'new-project' => Proc.new do
        require 'faastruby/cli/commands/project/new'
        FaaStRuby::Command::Project::New
      end,
      'deploy' => Proc.new do
        require 'faastruby/cli/commands/project/deploy'
        FaaStRuby::Command::Project::Deploy
      end,
      'test' => Proc.new do
        require 'faastruby/cli/commands/function/test'
        FaaStRuby::Command::Function::Test
      end,
      'run' => Proc.new do
        require 'faastruby/cli/commands/function/run'
        FaaStRuby::Command::Function::Run
      end,
      'add-credentials' => Proc.new do
        require 'faastruby/cli/commands/credentials/add'
        FaaStRuby::Command::Credentials::Add
      end,
      'list-credentials' => Proc.new do
        require 'faastruby/cli/commands/credentials/list'
        FaaStRuby::Command::Credentials::List
      end,
      'help' => Proc.new do
        FaaStRuby::Command::Help
      end,
      '-h' => Proc.new do
        require 'faastruby/cli/commands/help'
        FaaStRuby::Command::Help
      end,
      '--help' => Proc.new do
        require 'faastruby/cli/commands/help'
        FaaStRuby::Command::Help
      end,
      '-v' => Proc.new do
        require 'faastruby/cli/commands/version'
        FaaStRuby::Command::Version
      end,
      'watch' => Proc.new do
        require 'faastruby/local'
        FaaStRuby::Local.start!
      end
    }
  end
end
