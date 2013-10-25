module ShopifyTheme
  class Synchronizer
    attr_accessor :local_assets_list
    def initialize(client, configuration, options = {})
      @client = client
      @configuration = configuration
      @reporter = options.fetch(:reporter, nil)
    end

    def download(*args)
      assets = args.empty? ? local_assets_list : args
      result = assets.map do |asset|
        data = client.get_asset(asset)
        reporter.notice("Downloaded: #{asset}") if reporter
        data
      end
      reporter.notice("Done.") if reporter
      result
    end

    def local_assets_list
      @local_assets_list || []
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
  end
end