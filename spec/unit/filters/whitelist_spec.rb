require 'spec_helper'
require 'shopify_theme/filters/whitelist'

module ShopifyTheme
  module Filters
    describe "Whitelist" do
      WHITELIST_TEST_PATHS = %w(
          settings.html
          config/item1.html
          config/item2.html
          config/item3.html
          layout/thing1.html
          assets/application.css.liquid
          assets/application.js
          templates/thing2.html
          snippets/fancy.liquid
      )

      it "should use the default whitelist if nothing was provided" do
        whitelist = Whitelist.new
        expected = %w(
          config/item1.html
          config/item2.html
          config/item3.html
          layout/thing1.html
          assets/application.css.liquid
          assets/application.js
          templates/thing2.html
          snippets/fancy.liquid
        )
        assert_equal expected, whitelist.select(WHITELIST_TEST_PATHS)
      end

      it "should ignore the default 1+ whitelists were provided" do
        whitelist = Whitelist.new %w(settings.html config/item1.html config/item2.html config/item3.html layout/ templates/)
        expected = %w(settings.html config/item1.html config/item2.html config/item3.html layout/thing1.html templates/thing2.html)
        assert_equal expected, whitelist.select(WHITELIST_TEST_PATHS)
      end
    end
  end
end
