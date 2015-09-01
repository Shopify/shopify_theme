require 'spec_helper'
require 'shopify_theme/filters/whitelist'

module ShopifyTheme
  module Filters
    describe "Whitelist" do
      it "should only pick items that match the given list of patterns" do
        whitelist = Whitelist.new([
          "settings.html",
          "config/item1.html",
          "config/item2.html",
          "config/item3.html",
          "layout/",
          "templates/"
        ])
        paths = [
          "settings.html",
          "config/item1.html",
          "config/item2.html",
          "config/item3.html",
          "layout/thing1.html",
          "templates/thing2.html"
        ]
        expected = [
          "settings.html",
          "config/item1.html",
          "config/item2.html",
          "config/item3.html",
          "layout/thing1.html",
          "templates/thing2.html"
        ]
        assert_equal expected, whitelist.filter(paths)
      end
    end
  end
end
