require 'spec_helper'
require 'shopify_theme'

module ShopifyTheme
  describe "ShopifyTheme" do

    it "should raise an error if the code is not within the 200 or 300 series of response codes" do
      response = MiniTest::Mock.new
      response.expect(:code, 401)
      response.expect(:body, "Invalid API client")

      assert_raises ResponseError do
        ShopifyTheme.raise_for_error(response)
      end
    end

    it "should not raise an error if the code is a 200" do
      begin
        response = MiniTest::Mock.new
        response.expect(:code, 200)
        response.expect(:body, "Success")
        ShopifyTheme.raise_for_error(response)
        pass
      rescue => e
        flunk("An error should not have been raised. \n#{e.backtrace.join("\n")}")
        raise e
      end
    end
  end
end
