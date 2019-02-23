module FaaStRuby
  require 'faastruby/version'
  require 'faastruby/supported_runtimes'

  def self.get_crystal_version
    ver = `crystal -v|head -n1|cut -f2 -d' '`&.chomp
    ver == '' ? CRYSTAL_LATEST : ver
  end

  def self.crystal_present_and_supported?
    system("which crystal >/dev/null") && SUPPORTED_CRYSTAL.include?(get_crystal_version)
  end

  def self.ruby_present_and_supported?
    system("which ruby >/dev/null") && SUPPORTED_RUBY.include?(RUBY_VERSION)
  end

  CRYSTAL_ENABLED = crystal_present_and_supported?
  RUBY_ENABLED = ruby_present_and_supported?
  unless RUBY_ENABLED || CRYSTAL_ENABLED
    puts "\n[ERROR] You need to have one of the following language:version pairs in order to use FaaStRuby LocalKit."
    puts SUPPORTED_RUNTIMES.join(', ') + "\n"*2
    exit 1
  end
  PROJECT_ROOT = Dir.pwd
  CHDIR_MUTEX = Mutex.new
  CRYSTAL_VERSION = get_crystal_version.freeze if CRYSTAL_ENABLED
  DEFAULT_CRYSTAL_RUNTIME = "crystal:#{CRYSTAL_VERSION}".freeze
  DEFAULT_RUBY_RUNTIME = "ruby:#{RUBY_VERSION}".freeze
  require 'faastruby/server/logger'
  require 'faastruby/server/concurrency_controller'
  require 'faastruby/server/errors'
  require 'faastruby/server/event_channel'
  require 'faastruby/server/subscriber'
  require 'faastruby/server/event_hub'
  require 'faastruby/server/runner_methods'
  require 'faastruby/server/function_object'
  require 'faastruby/server/runner'
  require 'faastruby/server/event'
  require 'faastruby/server/response'
  require 'faastruby/server/sentinel'
  require 'faastruby/server/app'
end
