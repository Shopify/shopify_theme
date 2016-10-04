module ShopifyTheme
  module Filters
    class Whitelist
      DEFAULT_WHITELIST = %w(layout/ assets/ config/ snippets/ templates/ locales/ sections/)

      attr_reader :patterns

      def initialize(pattern_strings=[])
        @patterns = (pattern_strings.empty? ? DEFAULT_WHITELIST : pattern_strings).map { |pattern| Regexp.new(pattern) }
      end

      def select(list)
        list.select do |entry|
          patterns.any? { |pat| pat.match(entry) }
        end
      end
    end
  end
end
