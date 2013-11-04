require 'shopify_theme/reporters/reporter'
module ShopifyTheme
  module Reporters
    class NilReporter < Reporter
      def warn(message);end
      def error(message);end
      def notice(message);end
      def debug(message);end
    end
  end
end