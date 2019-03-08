require 'tty-table'
module FaaStRuby
  module Command
    module Workspace
      # require 'faastruby/cli/commands/workspace/base_command'
      require 'faastruby/cli/new_credentials'
      require 'oj'
      require 'fileutils'
      class Migrate < BaseCommand
        def initialize(args)
          @args = args
          @failed = []
          @migrated = []
          help
          load_credentials
        end

        def run
          file1 = File.expand_path('~/.faastruby')
          file2 = File.expand_path('~/.faastruby.tor1')
          if !File.file?(file1) && !File.file?(file2)
            puts "Nothing to migrate."
            exit 0
          end
          old_credential_files = [file1, file2]

          puts "@@@ WARNING @@@ WARNING @@@ WARNING @@@ WARNING @@@ ".red
          puts "This is going to migrate all your legacy credentials into your new account. This process is REQUIRED, but irreversible."
          email = NewCredentials::CredentialsFile.new.get['email']
          puts "You are currently logged in as '#{email}'."
          print "Continue? [y/N] "
          response = STDIN.gets.chomp
          FaaStRuby::CLI.error("Exiting", color: nil) unless response == 'y'
          old_credential_files.each do |file|
            next unless File.file?(file)
            FileUtils.cp(file, "#{file}.backup_before_migration") unless File.file?("#{file}.backup_before_migration")
            workspaces = Oj.load(File.read(file))
            workspaces.each do |workspace_name, credentials|
              migrate(workspace_name, credentials)
            end
            remove_migrated(file)
            backup_file(file)
          end
          notify_failed
        end

        def remove_migrated(file)
          credentials = Oj.load(File.read(file))
          @migrated.each do |workspace_name|
            credentials.delete(workspace_name)
          end
          File.write(file, JSON.pretty_generate(credentials))
        end

        def backup_file(file)
          FileUtils.mv(file, "#{file}.bkp")
        end

        def notify_failed
          return unless @failed.any?
          puts "\nThe following workspaces failed to be migrated: #{@failed.join(', ').red}"
          puts "Please come over to our Slack and we will assist you with this migration."
          puts "Click the following link to join our Slack: https://faastruby.io/slack\n\n"
        end

        def migrate(workspace_name, credentials)
          spinner = spin("Migrating workspace '#{workspace_name}'...")
          api = API.new
          response = api.migrate_to_account(workspace_name: workspace_name, api_key: credentials['api_key'], api_secret: credentials['api_secret'])
          if response.code > 299
            @failed << workspace_name
            spinner.stop(" Failed :(".red)
            return false
          end
          @migrated << workspace_name
          spinner.stop(" Done!".green)
          return true
        end

        def self.help
          "migrate-workspaces"
        end

        def usage
          puts "\n# Migrate legacy workspace credentials to your new FaaStRuby account."
          puts "# You must have an account and be logged in to perform the migration."
          puts "\nUsage: faastruby #{self.class.help}\n\n"
        end

      end
    end
  end
end
