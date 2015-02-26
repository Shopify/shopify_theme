require 'httparty'
require 'rss'

module ShopifyTheme
  FEED_URL = 'https://github.com/Shopify/Timber/releases.atom'
  ZIP_URL  = 'https://github.com/Shopify/Timber/archive/%s.zip'

  class Releases
    class VersionError < StandardError; end
    Release = Struct.new(:version) do
      def zip_url
        ZIP_URL % version
      end
    end

    def fetch!
      response = HTTParty.get(FEED_URL)
      raise "Could not retrieve feed from #{FEED_URL}" if response.code != 200
      @feed = RSS::Parser.parse(response.body)
    end

    def all
      @all ||= begin
        versioned_releases.reduce({'master' => master, 'latest' => latest}) do |all, release|
          all[release.version] = release
          all
        end
      end
    end

    def find(version)
      release = all[version]
      if release.nil?
        error = [
          "Invalid version '#{version}'.",
          "Valid versions are:",
        ].concat(all.keys.map{|v| "  #{v}"})
        raise VersionError, error.join("\n")
      end
      release
    end

    private
    def versioned_releases
      fetch! unless @feed
      @versioned_releases ||= @feed.items.map { |item| Release.new(item.title.content) }
    end

    def latest
      Release.new(versioned_releases.first.version)
    end

    def master
      Release.new('master')
    end
  end
end
