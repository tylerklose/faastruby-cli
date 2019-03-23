require 'yaml'
module FaaStRuby
  require 'faastruby/version'
  require 'faastruby/supported_runtimes'

  def self.get_crystal_version
    ver = `crystal -v|head -n1|cut -f2 -d' ' 2>/dev/null`&.chomp
    ver == '' ? CRYSTAL_LATEST : ver
  end

  def self.crystal_present_and_supported?
    system("which crystal >/dev/null") && version_match?(SUPPORTED_CRYSTAL, get_crystal_version)
  end

  def self.ruby_present_and_supported?
    system("which ruby >/dev/null") && version_match?(SUPPORTED_RUBY, RUBY_VERSION)
  end

  def self.version_match?(supported, current)
    supported.each {|supported_version| return true if Gem::Dependency.new('', supported_version).match?('', current)}
    return false
  end

  CRYSTAL_ENABLED = crystal_present_and_supported?
  RUBY_ENABLED = ruby_present_and_supported?
  unless RUBY_ENABLED || CRYSTAL_ENABLED
    puts "\n[ERROR] You need to have one of the following language:version pairs in order to use FaaStRuby Local."
    puts SUPPORTED_RUNTIMES.join(', ') + "\n\n"
    exit 1
  end
  SERVER_ROOT = Dir.pwd
  PROJECT_YAML_FILE = "#{SERVER_ROOT}/project.yml"
  unless File.file?(PROJECT_YAML_FILE)
    puts "\nERROR: Project configuration file not in current directory."
    puts "You can only run 'faastruby local' inside a Project directory."
    puts "To create a project, run 'faastruby new-project project-name'.\n\n"
    exit 1
  end
  SECRETS_FILE = ENV['FAASTRUBY_PROJECT_SECRETS_FILE'] || "#{SERVER_ROOT}/secrets.yml"
  PROJECT_NAME = YAML.load(File.read(PROJECT_YAML_FILE))['project']['name']
  SYNC_ENABLED = ENV['FAASTRUBY_PROJECT_SYNC_ENABLED']
  DEPLOY_ENVIRONMENT = ENV['FAASTRUBY_PROJECT_DEPLOY_ENVIRONMENT'] || 'stage'
  WORKSPACE_NAME = "#{PROJECT_NAME}-#{DEPLOY_ENVIRONMENT}"
  CHDIR_MUTEX = Mutex.new
  CRYSTAL_VERSION = get_crystal_version.freeze
  DEFAULT_CRYSTAL_RUNTIME = "crystal:#{CRYSTAL_VERSION}".freeze
  DEFAULT_RUBY_RUNTIME = "ruby:#{CURRENT_MINOR_RUBY}".freeze
  require 'faastruby/server/logger'
  require 'faastruby/server/project_config'
  require 'faastruby/server/local'
  FaaStRuby::Local.start!(deploy_env: DEPLOY_ENVIRONMENT, sync: SYNC_ENABLED, debug: ENV['DEBUG'])

  # require 'faastruby/server/concurrency_controller'
  require 'faastruby/server/errors'
  require 'faastruby/server/event_channel'
  require 'faastruby/server/subscriber'
  # require 'faastruby/server/event_hub'
  require 'faastruby/server/runner_methods'
  require 'faastruby/server/function_object'
  require 'faastruby/server/runner'
  require 'faastruby/server/event'
  require 'faastruby/server/response'
  # FaaStRuby::EventHub.listen_for_events!
  require 'faastruby/server/app'
end
