require 'spec_helper'
require 'shopify_theme'
require 'shopify_theme/api_checker'

module ShopifyTheme
  describe "APIChecker" do
    attr_reader :checker

    before do
      config = {
        api_key: 'abracadabra',
        password: 'alakazam',
        store: 'something.myshopify.com'
      }
      ShopifyTheme.config = config
      @checker = APIChecker.new(ShopifyTheme)
    end

    after do
      ShopifyTheme.config = nil
    end

    it "should return an APIResponse that says if the API is accessible when it gets a 200 response" do
      VCR.use_cassette("api_check_success") do
        response = checker.test_connectivity
        assert response.accessed_api?
      end
    end

    it "should return an APIResponse that says the API is down if it gets a 500-series response" do
      VCR.use_cassette("api_check_api_down") do
        response = checker.test_connectivity
        assert response.api_down?
      end
    end

    it "should return an APIResponse that says the client is misconfigured if it gets a 401 response" do
      VCR.use_cassette("api_check_unauthorized") do
        response = checker.test_connectivity
        assert response.invalid_config?
      end
    end
  end
end
