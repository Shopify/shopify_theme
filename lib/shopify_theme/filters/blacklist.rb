module ShopifyTheme
  module Filters
    class Blacklist
      attr_reader :patterns

      def initialize(pattern_strings=[])
        @patterns = pattern_strings.map { |p| Regexp.new(p)}
      end

      def select(list)
        list.select do |entry|
          patterns.none? { |pat| pat.match(entry) }
        end
      end
    end
  end
end
