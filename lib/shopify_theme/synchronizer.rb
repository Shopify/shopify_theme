require 'shopify_theme/reporters/nil_reporter'
require 'shopify_theme/storage/file_adapter'
require 'forwardable'
module ShopifyTheme
  class Synchronizer
    extend Forwardable
    def_delegators :@storage, :local_asset_list, :local_asset_contents

    attr_accessor :local_assets_list
    def initialize(client, configuration, options = {})
      @client = client
      @configuration = configuration
      @reporter = options.fetch(:reporter, ShopifyTheme::Reporters::NilReporter.new)
      @storage = options.fetch(:storage_adapter, ShopifyTheme::Storage::FileAdapter.new)
      @file_mapping = {}
    end

    def download(*args)
      return if args.empty?
      result = args.map do |asset|
        data = client.get_asset(asset)
        reporter.notice("Downloaded: #{asset}")
        data
      end
      reporter.notice("Done.")
      result
    end

    def download_and_save(*args)
      return if args.empty?
      args.each do |key|
        data = download(key)
        storage.process(key, data)
      end
    end

    private
    def client
      @client
    end

    def configuration
      @configuration
    end

    def reporter
      @reporter
    end

    def file_mapping
      @file_mapping
    end

    def storage
      @storage
    end
  end
end