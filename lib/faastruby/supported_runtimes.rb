module FaaStRuby
  # It is important that they are sorted in version order!
  SUPPORTED_RUBY = ['2.5.3', '2.6.0', '2.6.1']
  SUPPORTED_CRYSTAL = ['0.27.0', '0.27.2']
  CRYSTAL_LATEST = SUPPORTED_CRYSTAL.last
  RUBY_LATEST = SUPPORTED_RUBY.last
  SUPPORTED_RUNTIMES = SUPPORTED_RUBY.map{|version| "ruby:#{version}"} + SUPPORTED_CRYSTAL.map{|version| "crystal:#{version}"}
end