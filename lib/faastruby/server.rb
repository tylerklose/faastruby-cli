module FaaStRuby
  PROJECT_ROOT = Dir.pwd
  CHDIR_MUTEX = Mutex.new
  DEFAULT_CRYSTAL_RUNTIME = 'crystal:0.27.2'
  DEFAULT_RUBY_RUNTIME = 'ruby:2.6.1'
  require 'faastruby/version'
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
