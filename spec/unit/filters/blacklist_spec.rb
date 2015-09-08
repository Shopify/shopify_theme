require 'spec_helper'
require 'shopify_theme/filters/blacklist'


module ShopifyTheme
  module Filters
    describe "Blacklist" do
      BLACKLIST_TEST_PATHS = %w(
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

      it "should return the entire list back if initialized with no patterns" do
        blacklist = Blacklist.new
        assert_equal BLACKLIST_TEST_PATHS, blacklist.select(BLACKLIST_TEST_PATHS)
      end

      it "should return everything except for the items that matched the pattern" do
        blacklist = Blacklist.new(%w(config/* settings.html assets/* templates/* snippets/*))
        assert_equal %w(layout/thing1.html), blacklist.select(BLACKLIST_TEST_PATHS)
      end

    end
  end
end
