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
      attr_reader :parser

      def initialize(parser)
        @parser = parser
      end

      def configured?
        self.class.head('/assets.json').code == 200
      end

      def asset_list
        response = get('/assets.json', parser: parser)
        assets = parse(response)['assets'].map {|asset| asset['key']}
        assets.reject { |asset| assets.include? "#{asset}.liquid"}
      end

      def get_asset(asset)
        response = get('/assets.json', query: {asset: {key: asset}}, parser: parser)
        parse(response)['asset']
      end

      def send_asset(data)
        put('/assets.json', body: {asset: data})
      end

      def delete_asset(key)
        delete('/assets.json', body: {asset: {key: key}})
      end

      private

      def get(*args)
        self.class.get(*args)
      end

      def put(*args)
        self.class.put(*args)
      end

      def delete(*args)
        self.class.delete(*args)
      end

      def parse(response)
        JSON.parse(response.body)
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