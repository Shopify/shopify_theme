require 'spec_helper'
require 'shopify_theme/storage/string_adapter'

module ShopifyTheme
  module Storage
    describe "StringAdapter" do
      attr_reader :adapter
      before do
        @adapter = StringAdapter.new
      end

      it "should ignore whatever root is passed into it and use an empty hash" do
        adapter = StringAdapter.new({'assets/thing.png' => 'an image'})
        assert_equal({}, adapter.root)
      end

      it "should be able to store items" do
        adapter.store('assets/thing.png', 'an image', "w+b")
        assert adapter.root['assets/thing.png'], "There should be something stored at 'assetse/thing.png'"
      end

      it "should be able to provide a list of local assets" do
        adapter.store('assets/thing.png', 'an image', 'w+b')
        adapter.store('assets/other.png', 'an image', 'w+b')
        assert_equal %w(assets/thing.png assets/other.png).sort, adapter.local_asset_list.sort
      end

      it "should be able to provide the contents for an asset based on key" do
        adapter.store('assets/thing.png', 'an image', 'w+b')
        assert_equal 'an image', adapter.asset_contents('assets/thing.png')
      end
    end
  end
end