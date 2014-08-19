require 'spec_helper'
require 'shopify_theme'
require 'shopify_theme/cli'

module ShopifyTheme
  describe "Cli" do

    class CliDouble < Cli
      attr_writer :local_files, :mock_config

      desc "",""
      def config
        @mock_config || super
      end

      desc "",""
      def shop_theme_url
        super
      end

      desc "",""
      def binary_file?(file)
        super
      end

      desc "", ""
      def local_files
        @local_files
      end
    end

    before do
      @cli = CliDouble.new
      ShopifyTheme.config = {}
    end

    it "should remove assets that are not a part of the white list" do
      @cli.local_files = ['assets/image.png', 'config.yml', 'layout/theme.liquid', 'locales/en.default.json']
      local_assets_list = @cli.send(:local_assets_list)
      assert_equal 3, local_assets_list.length
      assert_equal false, local_assets_list.include?('config.yml')
    end

    it "should remove assets that are part of the ignore list" do
      ShopifyTheme.config = {ignore_files: ['config/settings.html']}
      @cli.local_files = ['assets/image.png', 'layout/theme.liquid', 'config/settings.html']
      local_assets_list = @cli.send(:local_assets_list)
      assert_equal 2, local_assets_list.length
      assert_equal false, local_assets_list.include?('config/settings.html')
    end

    it "should generate the shop path URL to the query parameter preview_theme_id if the id is present" do
      @cli.mock_config = {store: 'somethingfancy.myshopify.com', theme_id: 12345}
      assert_equal "somethingfancy.myshopify.com?preview_theme_id=12345", @cli.shop_theme_url
    end

    it "should generate the shop path URL withouth the preview_theme_id if the id is not present" do
      @cli.mock_config = {store: 'somethingfancy.myshopify.com'}
      assert_equal "somethingfancy.myshopify.com", @cli.shop_theme_url

      @cli.mock_config = {store: 'somethingfancy.myshopify.com', theme_id: ''}
      assert_equal "somethingfancy.myshopify.com", @cli.shop_theme_url
    end

    it "should report binary files as such" do
      extensions = %w(png gif jpg jpeg eot svg ttf woff otf swf ico pdf)
      extensions.each do |ext|
        assert @cli.binary_file?("hello.#{ext}"), "#{ext.upcase}s are binary files"
      end
    end

    it "should report unknown files as binary files" do
      assert @cli.binary_file?('omg.wut'), "Unknown filetypes are assumed to be binary"
    end

    it "should not report text based files as binary" do
      refute @cli.binary_file?('theme.liquid'), "liquid files are not binary"
      refute @cli.binary_file?('style.sass.liquid'), "sass.liquid files are not binary"
      refute @cli.binary_file?('style.css'), 'CSS files are not binary'
      refute @cli.binary_file?('application.js'), 'Javascript files are not binary'
      refute @cli.binary_file?('settings_data.json'), 'JSON files are not binary'
      refute @cli.binary_file?('applicaton.js.map'), 'Javascript Map files are not binary'
    end
  end
end
