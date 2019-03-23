module FaaStRuby
  # It is important that they are sorted in version order!
  SUPPORTED_RUBY = ['~> 2.5.0', '~> 2.6.0']
  SUPPORTED_CRYSTAL = ['0.27.0', '0.27.2']
  CRYSTAL_LATEST = SUPPORTED_CRYSTAL.last
  RUBY_LATEST = SUPPORTED_RUBY.last
  SUPPORTED_RUNTIMES = ['ruby:2.5', 'ruby:2.6'] + SUPPORTED_CRYSTAL.map{|version| "crystal:#{version}"}
  CURRENT_MINOR_RUBY = RUBY_VERSION.split('.')[0..1].join('.')
end