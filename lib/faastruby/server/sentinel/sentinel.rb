module FaaStRuby
  module Sentinel
    require 'listen'
    require 'tempfile'
    require 'pathname'
    require 'yaml'
    require 'faastruby/server/sentinel/base_handler'
    require 'faastruby/server/sentinel/crystal_builder'
    require 'faastruby/server/sentinel/function_handler'
    extend FaaStRuby::Logger::System
    STATIC_FILES_SYNC_ENABLED = SYNC_ENABLED && FaaStRuby::ProjectConfig.public_dir?
    @@threads = {}
    MUTEX = Mutex.new
    def self.pid
      @@pid
    end

    def self.add_thread(function_folder, key, value)
      MUTEX.synchronize do
        @@threads[function_folder] ||= {}
        @@threads[function_folder][key] = value
      end
    end
    def self.get_thread(function_folder, key)
      MUTEX.synchronize do
        return nil if @@threads[function_folder].nil?
        @@threads[function_folder][key]
      end
    end

    def self.get_threads
      MUTEX.synchronize do
        @@threads
      end
    end

    def self.tag
      '(WatchDog)'
    end

    def self.try_workspace
      try_to_create = Proc.new {system("faastruby create-workspace #{WORKSPACE_NAME}")}
      has_credentials = system("faastruby list-workspace #{WORKSPACE_NAME} > /dev/null 2>&1")
      continue = has_credentials || try_to_create.call
      unless continue
        FaaStRuby::CLI.error("Unable to setup project workspace '#{WORKSPACE_NAME}'. Make sure you have the credentials, or try a different environment name.\nExample: faastruby local --sync --deploy-env #{DEPLOY_ENVIRONMENT}-#{(rand * 100).to_i}")
      end
      true
    end

    def self.start!
      Dir.chdir SERVER_ROOT
      if SYNC_ENABLED
        try_workspace
        puts "#{tag} Sync mode enabled. Your functions will be auto-deployed to the workspace '#{WORKSPACE_NAME}'."
      end
      watched = [FaaStRuby::ProjectConfig.functions_dir, FaaStRuby::ProjectConfig.public_dir]
      @@listener = Listen.to(*watched) do |modified, added, removed|
        full_path, relative_path, subject, event = translate(modified, added, removed).flatten!
        puts "FULL_PATH: #{full_path}"
        puts "RELATIVE_PATH: #{relative_path}"
        puts "SUBJECT: #{subject}"
        puts "EVENT: #{event}"
        handle_event(full_path, relative_path, event, subject, @@listener)
        # Thread.new {}
      end
      @@listener.start
      sleep
    end

    def self.translate(modified, added, removed)
      return [modified[0], final_path_and_subject(modified[0].dup), :modified] if modified.any?
      return [added[0], final_path_and_subject(added[0].dup), :added] if added.any?
      return [removed[0], final_path_and_subject(removed[0].dup), :removed] if removed.any?
    end

    def self.final_path_and_subject(full_path)
      relative_path = relative_path_for(full_path)
      prefix = relative_path.slice!(/^(public|functions)\//)
      subject = :static if File.expand_path(prefix) == "#{FaaStRuby::ProjectConfig.public_dir}"
      subject = :function if File.expand_path(prefix) == "#{FaaStRuby::ProjectConfig.functions_dir}"
      [relative_path_for(full_path), subject]
    end

    def self.relative_path_for(full_path)
      full_path.slice!("#{SERVER_ROOT}/")
      full_path
    end

    def self.handle_event(full_path, relative_path, event, subject, listener)
      puts "Handling event"
      case subject
      when :static
        Sentinel::StaticFileHandler.perform(full_path, relative_path, event, listener)
      when :function
        Sentinel::FunctionHandler.perform(full_path, relative_path, event, listener)
      end
    end
  end
end