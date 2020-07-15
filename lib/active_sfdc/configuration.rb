module ActiveSfdc
  class << self
    attr_accessor :configuration
  end

  # configuration method for an initializer
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :sandboxed
    # salesforce credentials
    attr_accessor :username
    attr_accessor :password
    attr_accessor :security_token
    attr_accessor :client_id
    attr_accessor :client_secret
    attr_accessor :api_version
    attr_accessor :host
    attr_accessor :client

    # Checks if we are in read-only mode
    def sandboxed?
      return @sandboxed if defined?(@sandboxed)
      return (@sandboxed = ::Rails.application.sandbox) if defined?(::Rails) && defined?(::Rails.application.sandbox)
      @sandboxed = false
    end

    def client
      @client ||= ::Restforce.new(
        username: @username,
        password: @password,
        security_token: @security_token,
        client_id: @client_id,
        client_secret: @client_secret,
        api_version: @api_version,
        host: @host
      )
    end
  end
end
