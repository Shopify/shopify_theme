require 'shopify_theme/storage/storage_adapter'
module ShopifyTheme
  module Storage
    class StringAdapter < StorageAdapter
      attr_reader :root
      def initialize(root=nil)
        @root = {}
      end

      def store(key, content, format)
        root[key] = content
      end

      def local_asset_list
        root.keys
      end

      def asset_contents(key)
        root[key]
      end

      def destroy
        @root = {}
      end
    end
  end
end