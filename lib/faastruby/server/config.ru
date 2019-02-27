Puma::Single.prepend(Module.new do
  def stop
    super
  rescue NoMethodError
    Process.waitall
  end
end)
require 'faastruby/server'
run FaaStRuby::Server
