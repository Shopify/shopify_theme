require 'spec_helper'
require 'shopify_theme/synchronizer'

module ShopifyTheme
  describe "Synchronizer" do
    attr_reader :client, :synchronizer, :configuration
    before do
      @client = Minitest::Mock.new
      @configuration = Minitest::Mock.new
      @synchronizer = ShopifyTheme::Synchronizer.new(@client, @configuration, filesystem: Tempfile)
    end

    after do
      @synchronizer.files.each(&:unlink)
    end

    it "should be possible to pass in a directory"

    it "should be possible to get a list of files"


    it "should be able to download a file" do
      client.expect :get_asset, {key: 'assets/thing.js', value: '1234'}, ['assets/thing.js']
      synchronizer.download('assets/thing.js')
      client.verify
    end

    it "should be able to download multiple files" do
      client.expect :get_asset, {key: 'assets/thing.js', value: '1234'}, ['assets/thing.js']
      client.expect :get_asset, {key: 'assets/doodle.js', value: '4321'}, ['assets/doodle.js']
      synchronizer.download('assets/thing.js', 'assets/doodle.js')
      client.verify
    end

    it "should be able to download a file and save it" do
      client.expect :get_asset, {key: 'asset/thing.js', value: '1234'}, ['assets/thing.js']
      synchronizer.download_and_save('asset/thing.js')
      client.verify
      assert_equal 1, client.files.length
      assert_equal '1234', client.files.first.rewind.read
    end

    it "should be able to download and save multiple files"

    it "should be able to upload a file"

    it "should be able to upload multiple files"

    it "should be able to replace an asset online with a local asset"

    it "should upload the asset as an attachment when given a binary asset"

    it "should upload the asset as a value when given any other asset"

    it "should be able to replace all the assets for a theme with local assets"

    it "should be able to remove a remote file"

    it "should be able to watch a directory"

    it "should first convert binary data to Base64 before uploading"


  end
end