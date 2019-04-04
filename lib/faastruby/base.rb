module FaaStRuby
  require "faastruby/regions"
  ROOT_DOMAIN = ENV['FAASTRUBY_ROOT_DOMAIN'] || 'faastruby.io'
  WORKSPACE_BASE_HOST = ENV['FAASTRUBY_WORKSPACE_BASE_HOST'] || 'faast.cloud'
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

  def self.api_host
    ENV['FAASTRUBY_HOST'] || "https://api.#{region}.#{ROOT_DOMAIN}"
  end

  def self.workspace_host_for(workspace_name)
    "https://#{workspace_name}.#{region}.#{WORKSPACE_BASE_HOST}"
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
