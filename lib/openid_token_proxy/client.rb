require 'openid_connect'

module OpenIDTokenProxy
  class Client
    attr_reader :config

    def initialize(config = Config.instance)
      @config = config
    end

    def authorization_uri
      ENV['OPENID_AUTHORIZATION_URI'] || new_client.authorization_uri(
        domain_hint: config.domain_hint,
        prompt: config.prompt,
        resource: config.resource
      )
    end

    # Raised when auth code could not be exchanged
    class AuthCodeException < Exception; end

    # Retrieves a token for given authorization code
    def token_via_auth_code!(auth_code)
      client = new_client
      client.authorization_code = auth_code
      Token.new(client.access_token!(:query_string))
    rescue Rack::OAuth2::Client::Error => e
      raise AuthCodeException.new(e.message)
    end

    def new_client
      OpenIDConnect::Client.new(
        identifier:             config.client_id,
        secret:                 config.client_secret,
        authorization_endpoint: config.authorization_endpoint,
        token_endpoint:         config.token_endpoint,
        userinfo_endpoint:      config.userinfo_endpoint,
        redirect_uri:           config.redirect_uri
      )
    end

    def self.instance
      @instance ||= new
    end
  end
end