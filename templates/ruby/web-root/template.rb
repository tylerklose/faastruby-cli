require 'erb'

class Template
  def initialize(variables: {})
    variables.each do |var, value|
      instance_variable_set("@#{var}", value)
    end
  end

  def render(file)
    ERB.new(File.read(file)).result(binding)
  end
end