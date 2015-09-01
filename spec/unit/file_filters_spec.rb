require 'spec_helper'
require 'shopify_theme/file_filters'

module ShopifyTheme
  describe "FileFilters" do
    class IdentityFilter
      def select(list)
        list.select { true }
      end
    end

    class EvenFilter
      def select(list)
        list.select { |i| i % 2 == 0 }
      end
    end

    it "initializing without a filter raises an error" do
      assert_raises ArgumentError do
        FileFilters.new
      end
    end

    it "initializing with a single filter" do
      filters = FileFilters.new(IdentityFilter.new)
      assert_equal [1, 2, 3, 4, 5], filters.select([1, 2, 3, 4, 5])
    end

    it "initializing with a list of filters" do
      filters = FileFilters.new(IdentityFilter.new, EvenFilter.new)
      assert_equal [2, 4], filters.select([1, 2, 3, 4, 5])
    end
  end
end
