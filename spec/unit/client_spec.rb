require 'spec_helper'
require 'webmock'
require 'shopify_theme/configuration'
require 'shopify_theme/client'

module ShopifyTheme
  describe "Client" do
    include WebMock::API
    include MockResponses

    after do
      WebMock.reset!
    end

    def client(config=configuration)
      Client.new(config)
    end

    def configuration
      Configuration.new api_key: 'abracadabra', password: 'secrets', shop: 'funky.myshopify.com'
    end

    it "should be able to report if it is correctly configured" do
      response = {body: response('assets_list.json'), status: 200}
      mock_request(method: :head, response: response)
      assert client.configured?, "A 200 response from the API should report the client as correctly configured"
    end

    it "should be able to make a request to get a list of all assets on Shopify" do
      response = {body: response('assets_list.json'), status: 200}
      mock_request(response: response)
      assets = client.asset_list
      assert_equal 2, assets.length
    end

    it "should be able to make a request for a single asset" do
      response = {body: response('single_asset.json'), status: 200}
      query = {'asset' => {'key' => 'templates/search.liquid'}}
      mock_request(query: query, response: response)

      asset = client.get_asset('templates/search.liquid')
      assert_equal 802, asset['size']
    end

    it "should be able to make a request to upload an asset" do
      response = {body: response('single_asset.json'), status: 200}
      asset  = {asset: {value: 'updating my liquids'}}
      mock_request(method: :put, response: response) do |request|
        assert_equal 'asset[key]=templates%2Fsearch.liquid&asset[value]=updating%20my%20liquids', request.body
      end
      client.send_asset(key: 'templates/search.liquid', value: 'updating my liquids')
    end

    it "should be able to make a request to remove an asset" do
      mock_request(method: :delete) do |request|
        assert_equal 'asset[key]=templates%2Fsearch.liquid', request.body
      end
      client.delete_asset('templates/search.liquid')
    end


    def mock_request(opts = {}, &request_validator)
      config = opts.fetch(:configuration, configuration)
      response = opts[:response]
      method = opts.fetch(:method, :get)
      query = opts[:query]

      uri = config.shop_uri.gsub('https://', "https://#{config.api_key}:#{config.password}@")
      stubbed_request = stub_request(method, "#{uri}/assets.json")
      if request_validator
        stubbed_request = stubbed_request.with{|r| request_validator.call(r)}
      elsif query
        stubbed_request = stubbed_request.with(query: query)
      end
      stubbed_request.to_return(response) if response
    end

  end
end
