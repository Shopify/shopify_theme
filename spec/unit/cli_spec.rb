require 'spec_helper'
require 'shopify_theme'
require 'shopify_theme/cli'

module ShopifyTheme
  describe "Cli" do

    class CliDouble < Cli
      attr_writer :local_files

      desc "", ""
      def local_files
        @local_files
      end
    end

    before do
      @cli = CliDouble.new
    end

    it "should remove assets that are not a part of the white list" do
      @cli.local_files = ['assets/image.png', 'config.yml', 'layout/theme.liquid']
      assert_equal 2, @cli.send(:local_assets_list).length
      assert_equal false, @cli.send(:local_assets_list).include?('config.yml')
    end
  end
end
