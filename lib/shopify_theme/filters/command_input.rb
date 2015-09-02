module ShopifyTheme
  module Filters
    class CommandInput
      attr_reader :patterns
      def initialize(inputs=[])
        @patterns = inputs.map { |i| Regexp.compile(i) }
      end

      def select(list)
        return list if patterns.empty?
        list.select { |entry|
          patterns.any? { |pat| pat.match(entry) }
        }
      end
    end
  end
end
