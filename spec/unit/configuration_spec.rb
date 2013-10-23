require 'spec_helper'
require 'shopify_theme/configuration'

module ShopifyTheme
  describe "Configuration" do
    it "should complain that ignore_files is deprecated if it is in the configuration" do
      reporter = MiniTest::Mock.new
      reporter.expect(:error, nil, [String])
      reporter.expect(:warn, nil, [':ignore_files: is deprecated. Use :whitelist_files: instead'])
      Configuration.new({ignore_files: ['README.md']}, reporter)
      reporter.verify
    end

    it "should gracefully handle when an empty configuration is passed in" do
      reporter = MiniTest::Mock.new
      reporter.expect(:error, nil, ['An empty configuration file was provided. Communication with Shopify is not possible!'])
      Configuration.new({}, reporter)
      reporter.verify
    end

    it "should raise a warning when a configuration is missing the required keys" do
      configuration = {
        api_key: 'abracadabra',
        store: 'little-plastics.myshopify.com'
      }
      reporter = MiniTest::Mock.new
      reporter.expect(:error, nil, ['Configuration is missing key(s): password'])
      Configuration.new(configuration, reporter)
      reporter.verify
    end

    it "should raise an error if a nil object was passed in as the configuration" do
      assert_raises Configuration::MissingConfiguration do
        Configuration.new(nil)
      end
    end

    it "should generate the theme path based on the value of the theme_id in the provided configuration" do
      configuration = Configuration.new(theme_id: 1234)
      assert_equal '/admin/themes/1234/assets.json', configuration.theme_path
      assert_equal '/admin/themes/1234/assets.json', configuration.path

      configuration = Configuration.new(theme_id: nil)
      assert_equal '/admin/assets.json', configuration.theme_path
      assert_equal '/admin/assets.json', configuration.path
    end

    it "should be able to provide information about what the file whitelist is" do
      whitelist = {whitelist_files: %w(important_file.txt other_file.txt)}
      configuration = Configuration.new(whitelist)
      assert_equal ['important_file.txt', 'other_file.txt'], configuration.whitelist_files
    end

    it "should be able to handle when the whitelist_files are missing" do
      configuration = Configuration.new({})
      assert_equal [], configuration.whitelist_files
    end

    it "should be able to provide information about what the file blacklist is" do
      blacklist = {blacklist_files: %w(README.md)}
      configuration = Configuration.new(blacklist)
      assert_equal ['README.md'], configuration.blacklist_files
    end

    it "should be able to handle when the blacklist_files are missing" do
      configuration = Configuration.new({})
      assert_equal [], configuration.blacklist_files
    end

    it "should be able to provide the api_key" do
      configuration = Configuration.new(api_key: 'token')
      assert_equal 'token', configuration.api_key
    end

    it "should be able to provide the password" do
      configuration = Configuration.new(password: 'secrets')
      assert_equal 'secrets', configuration.password
    end

    it "should be able to calculate the shop_uri based on the shop name" do
      configuration = Configuration.new(shop: 'funky.myshopify.com')
      assert_equal 'https://funky.myshopify.com', configuration.shop_uri
    end

    it "should be able to expand the shop name into the full myshopify name" do
      configuration = Configuration.new(shop: 'funky')
      assert_equal 'https://funky.myshopify.com', configuration.shop_uri
    end

  end
end