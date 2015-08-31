require 'spec_helper'
require 'shopify_theme'
require 'shopify_theme/api_checker'

module ShopifyTheme
  describe "APIChecker" do
    include WebMock::API
    attr_reader :checker
    before do
      ShopifyTheme.config = {
        api_key: 'abracadabra',
        password: 'alakazam',
        store: 'something.myshopify.com'
      }
      @checker = APIChecker.new(ShopifyTheme)
    end

    after do
      ShopifyTheme.config = nil
    end

    it "should return an APIResponse that says if the API is accessible when it gets a 200 response" do
      VCR.use_cassette("api_check_success") do
        stub_request(:get, request_root).to_return(body: "OK", status: 200)
        response = checker.test_connectivity
        assert response.accessed_api?
      end
    end

    it "should return an APIResponse that says the API is down if it gets a 500-series response" do
      VCR.use_cassette("api_check_api_down") do
        stub_request(:get, request_root).to_return(body: "DOWN", status: 503)
        response = checker.test_connectivity
        assert response.api_down?
      end
    end

    it "should return an APIResponse that says the client is misconfigured if it gets a 401 response" do
      VCR.use_cassette("api_check_unauthorized") do
        stub_request(:get, request_root).to_return(body: "DENIED", status: 401)
        response = checker.test_connectivity
        assert response.invalid_config?
      end
    end

    def request_root
      "https://abracadabra:alakazam@something.myshopify.com"
    end
  end
end
