module ShopifyTheme
  module Reporters
    class Reporter

      def warn(message)
        raise NotImplementedError.new("To be implemented by subclass")
      end

      def error(message)
        raise NotImplementedError.new("To be implemented by subclass")
      end

      def notice(message)
        raise NotImplementedError.new("To be implemented by subclass")
      end

      def debug(message)
        raise NotImplementedError.new("To be implemented by subclass")
      end
    end
  end
end