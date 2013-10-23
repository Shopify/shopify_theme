require 'spec_helper'
require 'webmock'
require 'shopify_theme/configuration'
require 'shopify_theme/client'

module ShopifyTheme
  describe "Client" do
    include WebMock::API
    include MockResponses
    def client(config)
      Client.new(config)
    end

    def configuration
      Configuration.new api_key: 'abracadabra', password: 'secrets', shop: 'funky.myshopify.com'
    end

    it "should be able to report if it is correctly configured" do
      response = {body: response('assets_list.json'), status: 200}
      mock_request(:get, configuration, response)
      client = client(configuration)
      assert client.configured?, "A 200 response from the API should report the client as correctly configured"
    end

    it "should be able to make a request to get a list of all assets on Shopify" do
      response = {body: response('assets_list.json'), status: 200}
      mock_request(:get, configuration, response)
      assets = client(configuration).asset_list
      assert_equal 2, assets.length
    end

    it "should be able to make a request for a single asset"

    it "should be able to make a request to upload an asset"

    it "should be able to make a request to remove an asset"


    def mock_request(method, config, response=nil, &request_validator)
      uri = config.shop_uri.gsub('https://', "https://#{config.api_key}:#{config.password}@")
      stubbed_request = stub_request(method, uri)
      stubbed_request = stubbed_request.with{|r| request_validator.call(r)}  if block_given?
      stubbed_request.to_return(response) if response
    end

  end
end