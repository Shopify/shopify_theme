require 'yaml'

module ShopifyTheme
  class Configuration
    REQUIRED_KEYS = [:api_key, :password, :store]

    class MissingConfiguration < StandardError; end

    def initialize(configuration, reporter=nil)
      raise MissingConfiguration.new("Configuration cannot be nil") unless configuration
      @config = configuration
      @reporter = reporter
      verify if reporter
    end

    def theme_path
      if theme_id
        "/admin/themes/#{theme_id}/assets.json"
      else
        "/admin/assets.json"
      end
    end
    alias_method :path, :theme_path

    def whitelist_files
      @whitelist_files ||= read_array_attr(:whitelist_files)
    end

    def blacklist_files
      @blacklist_files ||= read_array_attr(:blacklist_files)
    end

    def api_key
      config[:api_key]
    end

    def password
      config[:password]
    end

    def shop_uri
      shop = config[:shop]
      shop = shop.include?('myshopify.com') ? shop : "#{shop}.myshopify.com"
      "https://#{shop}"
    end

    private
    def reporter
      @reporter
    end

    def config
      @config
    end

    def read_array_attr(key)
      (config[key] || []).compact
    end

    def theme_id
      config[:theme_id]
    end

    def verify
      reporter.warn ":ignore_files: is deprecated. Use :whitelist_files: instead" if config[:ignore_files]

      if config.keys.flatten.length <= 0
        reporter.error "An empty configuration file was provided. Communication with Shopify is not possible!"
        return
      end

      unless (missing_keys = REQUIRED_KEYS - config.keys.flatten).length == 0
        reporter.error "Configuration is missing key(s): #{missing_keys.join(',')}"
      end
    end
  end
end