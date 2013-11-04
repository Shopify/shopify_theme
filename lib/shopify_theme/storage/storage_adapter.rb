module ShopifyTheme
  module Storage
    class StorageAdapter

      def process(key, data)
        format = "w"
        content = if data['value']
          data['value'].gsub("\r", "")
        elsif data['attachment']
          format += "+b"
          Base64.decode64(data['attachment'])
        else
          nil
        end

        store(key, content, format)
      end

      def store(key, content, format)
        raise NotImplementedError.new("#store to be implemented by subclass")
      end

      def local_asset_list
        raise NotImplementedError.new("#local_asset_list to be implemented by subclass")
      end

      def local_asset_contents(key)
        raise NotImplementedError.new("#local_asset_contents to be implemented by subclass")
      end
    end
  end
end