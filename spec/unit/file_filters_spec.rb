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
      begin
        FileFilters.new(IdentityFilter.new)
      rescue Error => e
        flunk("Initializing with a single filter should not fail. #{e}")
      end
    end

    it "should only select entries that were valid for all of the given filters" do
      filters = FileFilters.new(IdentityFilter.new, EvenFilter.new)
      assert_equal [2, 4], filters.select([1, 2, 3, 4, 5])
    end
  end
end
