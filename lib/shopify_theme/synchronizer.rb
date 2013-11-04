require 'shopify_theme/reporters/nil_reporter'
require 'base64'
require 'fileutils'
module ShopifyTheme
  class Synchronizer
    attr_accessor :local_assets_list
    def initialize(client, configuration, options = {})
      @client = client
      @configuration = configuration
      @reporter = options.fetch(:reporter, ShopifyTheme::Reporters::NilReporter.new)
      @filesystem = options.fetch(:filesystem, File)
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
        file = process(key, data)

      end
    end

    def local_assets_list
      file_mapping.map { |name, _| name }
    end

    def files
      file_mapping.map{ |_, file_handle| file_handle }
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

      FileUtils.mkdir_p(File.dirname(key))
      File.open(key, format){|f| f.write(content)} if content
    end
  end
end