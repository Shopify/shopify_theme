require 'httparty'

module ShopifyTheme
  class Client
    NOOPParser = ->(data, format){}

    class << self
      # This makes our API Client thread-safe
      # http://rubyscale.com/blog/2012/09/24/being-classy-with-httparty/
      def new(configuration, parser=NOOPParser)
        klazz = Class.new(AbstractClient) do |klass|
          klass.base_uri(configuration.shop_uri)
          klass.basic_auth configuration.api_key, configuration.password
        end
        klazz.new(parser)
      end
    end

    class AbstractClient
      include HTTParty

      def initialize(parser)
        @parser = parser
      end

      def configured?
        self.class.get('').code == 200
      end

      def asset_list
        []
      end
    end


    def initialize(configuration, parser=NOOPParser)
      @parser = parser
      @auth = {username: configuration.api_key, }
      basic_auth configuration.api_key, configuration.password
      base_uri configuration.shop_uri
    end
  end
end