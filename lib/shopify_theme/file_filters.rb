require 'shopify_theme/filters/blacklist'
require 'shopify_theme/filters/whitelist'
require 'shopify_theme/filters/command_input'

module ShopifyTheme
  class FileFilters
    def initialize(*filters)
      raise ArgumentError, "Must have at least one filter to apply" unless filters.length > 0
      @filters = filters
    end

    def select(list)
      @filters.reduce(list) do |results, filter|
        filter.select(results)
      end
    end
  end
end
