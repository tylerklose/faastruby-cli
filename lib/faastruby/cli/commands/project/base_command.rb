module FaaStRuby
  module Command
    module Project
      PROJECT_YAML_FILE = 'project.yml'
      PROJECT_CREDENTIALS_FILE = '.credentials.yml'
      class ProjectBaseCommand < BaseCommand
        def read_credentials_file
          File.file?(PROJECT_CREDENTIALS_FILE)
        end
      end
    end
  end
end