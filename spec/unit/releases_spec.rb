require 'spec_helper'
require 'shopify_theme'
require 'shopify_theme/releases'

module ShopifyTheme
  describe 'Releases' do

    before do
      VCR.use_cassette("timber_releases") do
        @releases = Releases.new
        @releases.fetch!
      end
    end

    it "should provide a list of all the available releases" do
      versions = @releases.all.keys
      assert_equal true, versions.include?('latest')
      assert_equal true, versions.include?('v2.0.2')
      assert_equal true, versions.include?('v2.0.1')
    end

    it "should be able to find a specific release" do
      release = @releases.find('v2.0.2')
      assert_equal 'v2.0.2', release.version
    end

    it "should raise an error if the version does not exist" do
      assert_raises Releases::VersionError do
        @releases.find('reccomended')
      end
    end

    it "should provide a zip URL for a release" do
      assert_equal "https://github.com/Shopify/Timber/archive/v2.0.2.zip", @releases.all['v2.0.2'].zip_url
    end

    it "should provide a zip URL for the latest release" do
      assert_equal "https://github.com/Shopify/Timber/archive/v2.0.2.zip", @releases.all['latest'].zip_url
    end

    it 'should provide a zip URL for the master release' do
      assert_equal "https://github.com/Shopify/Timber/archive/master.zip", @releases.all['master'].zip_url
    end
  end
end
