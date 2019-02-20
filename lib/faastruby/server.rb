module FaaStRuby
  PROJECT_ROOT = Dir.pwd
  CHDIR_MUTEX = Mutex.new
  CRYSTAL_VERSION = `crystal -v|head -n1|cut -f2 -d' '` || CRYSTAL_LATEST
  DEFAULT_CRYSTAL_RUNTIME = "crystal:#{CRYSTAL_VERSION}"
  DEFAULT_RUBY_RUNTIME = "ruby:#{RUBY_VERSION}"
  require 'faastruby/version'
  require 'faastruby/supported_runtimes'
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
