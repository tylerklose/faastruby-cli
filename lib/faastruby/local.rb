STDOUT.sync
module FaaStRuby
  module Local
    require 'listen'
    require 'colorize'
    require 'open3'
    require 'oj'
    require 'yaml'
    require 'pathname'
    require 'securerandom'
    require 'faastruby/version'
    require 'faastruby/supported_runtimes'
    require 'faastruby/local/logger'
    require 'faastruby/local/functions'
    require 'faastruby/local/static_files'
    require 'faastruby/local/listeners'
    require 'faastruby/local/processors'
    require 'faastruby/local/monkey_patch'
    extend Local::Logger

    def self.get_crystal_version
      debug "self.get_crystal_version"
      ver = `crystal -v|head -n1|cut -f2 -d' ' 2>/dev/null`&.chomp
      ver == '' ? CRYSTAL_LATEST : ver
    end

    def self.crystal_present_and_supported?
      debug "self.crystal_present_and_supported?"
      system("which crystal >/dev/null") && SUPPORTED_CRYSTAL.include?(get_crystal_version)
    end

    def self.ruby_present_and_supported?
      debug "self.ruby_present_and_supported?"
      system("which ruby >/dev/null") && SUPPORTED_RUBY.include?(RUBY_VERSION)
    end

    def self.check_if_logged_in
      creds_file = File.expand_path("~/.faastruby/credentials.yml")
      yaml = YAML.load(File.read(creds_file)) rescue {}
      unless yaml['credentials'] && yaml['credentials']['email']
        STDOUT.puts "@@@ WARNING @@@ | You need to be logged in to use FaaStRuby Local with sync mode.".red
        STDOUT.puts "@@@ WARNING @@@ | To login, run: faastruby login".red
        STDOUT.puts "@@@ WARNING @@@ | Sync mode is *NOT* enabled!".red
        STDOUT.puts "---".red
        return false
      end
      return true
    end

    DEBUG = ENV['DEBUG']
    CRYSTAL_ENABLED = crystal_present_and_supported?
    RUBY_ENABLED = ruby_present_and_supported?
    unless RUBY_ENABLED || CRYSTAL_ENABLED
      puts "\n[ERROR] You need to have one of the following 'language:version' pairs in order to use FaaStRuby Local."
      puts SUPPORTED_RUNTIMES.join(', ') + "\n"*2
      exit 1
    end
    SERVER_ROOT = Dir.pwd
    PROJECT_YAML_FILE = "#{SERVER_ROOT}/project.yml"
    SECRETS_YAML_FILE = "#{SERVER_ROOT}/secrets.yml"
    DEPLOY_ENVIRONMENT = ENV['DEPLOY_ENVIRONMENT'] || 'stage'
    SYNC_ENABLED = ENV['SYNC'] && check_if_logged_in
    CRYSTAL_VERSION = get_crystal_version.freeze
    DEFAULT_CRYSTAL_RUNTIME = "crystal:#{CRYSTAL_VERSION}".freeze
    DEFAULT_RUBY_RUNTIME = "ruby:#{RUBY_VERSION}".freeze
    FUNCTIONS_EVENT_QUEUE = Queue.new
    PUBLIC_EVENT_QUEUE = Queue.new

    def self.workspace
      debug "self.workspace"
      return "#{project_config['name']}-#{DEPLOY_ENVIRONMENT}-#{project_config['identifier']}" if project_config['identifier']
      "#{project_config['name']}-#{DEPLOY_ENVIRONMENT}"
    end

    def self.project_config
      debug "self.project_config"
      yaml = YAML.load(File.read(PROJECT_YAML_FILE))['project']
    end
    def self.functions_dir
      debug "self.functions_dir"
      "#{SERVER_ROOT}/#{project_config['functions_dir'] || 'functions'}"
    end

    def self.public_dir
      debug "self.public_dir"
      "#{SERVER_ROOT}/#{project_config['public_dir'] || 'public'}"
    end

    def self.root_to
      debug "self.root_to"
      project_config['root_to'] || 'root'
    end

    def self.catch_all
      debug "self.catch_all"
      project_config['catch_all'] || 'catch-all'
    end

    def self.functions
      debug "self.functions"
      @@functions ||= []
    end

    def self.secrets_for_function(function_name)
      debug "self.secrets_for_function(#{function_name.inspect})"
      deploy_environment_secrets[function_name] || {}
    end

    def self.deploy_environment_secrets
      debug "self.deploy_environment_secrets"
      secrets[DEPLOY_ENVIRONMENT] || {}
    end

    def self.secrets
      debug "self.secrets"
      YAML.load(File.read(SECRETS_YAML_FILE))['secrets'] || {}
    end

    def self.start!
      Listen::Adapter::Linux::DEFAULTS[:events] << :modify
      debug "self.start!"
      sync_mode_enabled if SYNC_ENABLED
      @@functions = Function.find_all_in(functions_dir)
      ruby_functions = @@functions.map{|f| f.name if f.language == "ruby"}.compact
      crystal_functions = @@functions.map{|f| f.name if f.language == "crystal"}.compact
      puts "Detecting existing functions."
      puts "Ruby functions: #{ruby_functions.inspect}"
      puts "Crystal functions: #{crystal_functions.inspect}"
      listen_on_functions_dir
      listen_on_public_dir if SYNC_ENABLED
      initial_compile_and_deploy(crystal_functions)
      puts "Listening for changes."
      FunctionProcessor.new(FUNCTIONS_EVENT_QUEUE).start
      StaticFileProcessor.new(PUBLIC_EVENT_QUEUE).start if SYNC_ENABLED
      sleep
    ensure
      puts "Stopping Watchdog..."
      Local::Listener.functions_listener.each(&:stop)
      Local::Listener.public_listener.each(&:stop)
    end

    def self.initial_compile_and_deploy(crystal_functions)
      debug "initial_compile_and_deploy(#{crystal_functions.inspect})"
      puts "Triggering 'compile' on Crystal functions." if crystal_functions.any?
      if SYNC_ENABLED
        puts "Running initial cloud sync."
        StaticFile.full_sync
      end
      sleep 1
      @@functions.each {|f| FileUtils.touch("#{f.absolute_folder}/faastruby.yml")}
    end

    def self.sync_mode_enabled
      debug __method__
      puts "Sync mode enabled."
      print "Connecting to workspace '#{workspace}'... "
      try_to_create = Proc.new {system("faastruby create-workspace #{workspace}")}
      has_credentials = system("faastruby list-workspace #{workspace} > /dev/null 2>&1")
      continue = has_credentials || try_to_create.call
      unless continue
        puts "[FATAL] Unable to setup project workspace '#{workspace}'. Make sure you have the credentials, or try a different environment name.\nExample: faastruby local --sync --deploy-env #{DEPLOY_ENVIRONMENT}-#{(rand * 100).to_i}".red
        exit 1
      end
      STDOUT.puts "connected!\n".yellow
      puts "Your local environment will be synced to https://#{workspace}.tor1.faast.cloud"
      true
    end

    def self.listen_on_functions_dir
      debug "self.listen_on_functions_dir"
      debug "Listening for changes in '#{functions_dir}'"
      listener = Listener.new(directory: functions_dir, queue: FUNCTIONS_EVENT_QUEUE)
      listener.start
      Local::Listener.functions_listener << listener
    end

    def self.listen_on_public_dir
      debug "self.listen_on_public_dir"
      debug "Listening for changes in '#{public_dir}'"
      listener = Listener.new(directory: public_dir, queue: PUBLIC_EVENT_QUEUE)
      listener.start
      Local::Listener.public_listener << listener
    end
  end
end