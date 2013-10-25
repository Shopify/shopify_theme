require 'shopify_theme/reporters/reporter'
module ShopifyTheme
  module Reporters
    class ThorReporter < Reporter
      def initialize(thor)
        @thor = thor
      end

      def error(message)
        thor.say(message, :red)
      end

      def warn(message)
        thor.say(message, :yellow)
      end

      def notice(message)
        thor.say(message, :green)
      end

      def debug(message)
        thor.say(message, :magenta)
      end

      private
      def thor
        @thor
      end
    end
  end
end