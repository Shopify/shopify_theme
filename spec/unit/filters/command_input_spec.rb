require 'spec_helper'
require 'shopify_theme/filters/command_input'

module ShopifyTheme
  module Filters
    describe "CommandInput" do
      it "should return the entire list if initialized with nothing" do
        filter = CommandInput.new([])
        assert_equal %w(a b c d e f), filter.select(%w(a b c d e f))
      end

      it "should return a subset if initialized with some values" do
        filter = CommandInput.new(%w(a c d))
        assert_equal %w(a c d a), filter.select(%w(a b c d e a f))
      end
    end
  end
end
