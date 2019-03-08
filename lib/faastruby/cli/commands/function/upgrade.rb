# module FaaStRuby
#   module Command
#     module Function
#       require 'faastruby/cli/commands/function/base_command'
#       class Upgrade < FunctionBaseCommand
#         def initialize(args)
#           @args = args
#         end

#         def run
#           check_function_name
#           set_yaml_content
#           write_yaml
#           write_gemfile
#           copy_spec_folder
#           puts "Upgrade complete. Please read the documentation at https://faastruby.io/tutorial.html to learn about the changes."
#           puts "To deploy, run 'faastruby deploy-to WORKSPACE_NAME'."
#         end

#         def set_yaml_content
#           @yaml_content = {
#             'name' => @function_name,
#             'test_command' => nil,
#             'abort_build_when_tests_fail' => false,
#             'abort_deploy_when_tests_fail' => false
#           }
#         end

#         def check_function_name
#           FaaStRuby::CLI.error('You need to run this command from the function directory') unless File.file?('handler.rb')
#           @function_name = Dir.pwd.split('/').last
#           unless @function_name
#             puts "What's the name of this function? (accepts only letters, numbers, - or _)"
#             print "Enter function name: "
#             @function_name = STDIN.gets.chomp
#           end
#           FaaStRuby::CLI.error('You need to provide a valid function name (letters, numbers, - or _)') unless @function_name.match(/^[a-zA-Z\-_0-9]{1,}$/)
#         end

#         def write_yaml
#           write_file("./faastruby.yml", @yaml_content.to_yaml)
#         end

#         def write_gemfile
#           content = "\n# Added by 'faastruby upgrade'\ngroup :test do\n  gem 'rspec'\nend\n"
#           write_file("./Gemfile", content, 'a')
#         end

#         def copy_spec_folder
#           @base_dir = '.'
#           source = "#{Gem::Specification.find_by_name("faastruby").gem_dir}/example-blank"
#           FileUtils.cp_r("#{source}/spec", "#{@base_dir}/")
#           puts "+ d #{@base_dir}/spec".green
#           puts "+ d #{@base_dir}/spec/helpers".green
#           puts "+ f #{@base_dir}/spec/helpers/faastruby.rb".green
#           puts "+ f #{@base_dir}/spec/handler_spec.rb".green
#           puts "+ f #{@base_dir}/spec/spec_helper.rb".green
#         end

#         def self.help
#           "upgrade"
#         end

#         def usage
#           "Usage: faastruby #{self.class.help}"
#         end
#       end
#     end
#   end
# end
