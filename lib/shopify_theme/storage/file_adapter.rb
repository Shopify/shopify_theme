require 'shopify_theme/storage/storage_adapter'
require 'fileutils'
module ShopifyTheme
  module Storage
    class FileAdapter < StorageAdapter
      attr_reader :root
      def initialize(root)
        @root = File.expand_path(root)
      end

      def store(key, content, format)
        FileUtils.mkdir_p(File.dirname(key))
        File.open(key, format){|f| f.write(content)} if content
      end

      def local_asset_list
        Dir.glob("#{root}/**", "#{root}/*")
      end

      def asset_contents(key)
        File.read(File.absolute_path(key, root))
      end

      def destroy
        FileUtils.rm_r(root) if ENV['test']
      end
    end
  end
end