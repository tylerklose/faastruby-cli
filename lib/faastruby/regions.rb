module FaaStRuby
  DEFAULT_REGION = 'tor1'
  REGIONS = [
    'tor1'
  ]

  def self.region
    ENV['FAASTRUBY_REGION'] ||= DEFAULT_REGION
    raise "No such region: #{ENV['FAASTRUBY_REGION']}" unless FaaStRuby::REGIONS.include?(ENV['FAASTRUBY_REGION'])
    ENV['FAASTRUBY_REGION']
  end
end