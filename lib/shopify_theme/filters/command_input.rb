module ShopifyTheme
  module Filters
    class CommandInput
      def initialize(inputs=[])
        @patterns = inputs.map { |i| Regexp.compile(i) }
      end
    end

    def select(list)
      return list if inputs.empty?
      list.select { |entry|
        patterns.any? { |pat| pat.match(entry) }
      }
    end
  end
end
