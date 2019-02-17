module FaaStRuby
  ROOT_DOMAIN = ENV['FAASTRUBY_ROOT_DOMAIN'] || 'faastruby.io'
  WORKSPACE_BASE_HOST = ENV['FAASTRUBY_WORKSPACE_BASE_HOST'] || 'faast.cloud'
  DEFAULT_REGION = 'tor1'
  REGIONS = [
    'tor1'
  ]
  class << self
    attr_accessor :configuration
  end

  def self.api_key
    configuration&.api_key || ENV['FAASTRUBY_API_KEY']
  end

  def self.api_secret
    configuration&.api_secret || ENV['FAASTRUBY_API_SECRET']
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.credentials
    {api_key: api_key, api_secret: api_secret}
  end

  def self.region
    ENV['FAASTRUBY_REGION'] ||= DEFAULT_REGION
    raise "No such region: #{ENV['FAASTRUBY_REGION']}" unless FaaStRuby::REGIONS.include?(ENV['FAASTRUBY_REGION'])
    ENV['FAASTRUBY_REGION']
  end

  def self.api_host
    ENV['FAASTRUBY_HOST'] || "https://api.#{region}.#{ROOT_DOMAIN}"
  end

  def self.workspace_host_for(workspace_name)
    "https://#{workspace_name}.#{region}.#{WORKSPACE_BASE_HOST}"
  end

  def self.credentials_file
    return File.expand_path(ENV['FAASTRUBY_CREDENTIALS']) if ENV['FAASTRUBY_CREDENTIALS']
    if region == DEFAULT_REGION && File.file?(File.expand_path('~/.faastruby'))
      return File.expand_path('~/.faastruby')
    elsif region == DEFAULT_REGION
      return File.expand_path("~/.faastruby.#{region}")
    else
      return File.expand_path("~/.faastruby.#{region}")
    end
  end

  class Configuration
    attr_accessor :api_key, :api_secret
  end


  class BaseObject
    def initialize(params = {}, &block)
      @errors = []
      @api = API.new
      self.mass_assign(params) if params
      yield self if block_given?
    end

    def assign_attributes(params = {}, &block)
      self.mass_assign(params) if params
      yield self if block_given?
    end

    def attributes=(params)
      assign_attributes(params)
    end

    def mass_assign(attrs)
      attrs.each do |key, value|
        self.public_send("#{key}=", value)
      end
    end
  end
end
