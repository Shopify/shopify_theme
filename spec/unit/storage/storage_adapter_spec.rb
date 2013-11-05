require 'spec_helper'
require 'shopify_theme/storage/storage_adapter'

module ShopifyTheme
  module Storage
    class TestStorageAdapter < StorageAdapter
      attr_accessor :spy
      def initialize
        @spy = Minitest::Mock.new
      end

      def store(k, c, f)
        spy.store(k, c, f)
      end
    end

    describe "StorageAdapter" do
      attr_reader :adapter
      before do
        @adapter = TestStorageAdapter.new
      end

      it "should be able to process data that contains a simple value" do
        adapter.spy.expect :store, nil, ['something.txt', 'something', 'w']
        adapter.process({'key' => 'something.txt', 'value' => 'something'})
        adapter.spy.verify
      end

      it "should be able to process data that contains a binary attachment" do
        adapter.spy.expect :store, nil, ['something.txt', 'something', 'w+b']
        adapter.process({'key' => 'something.txt', 'attachment' => 'c29tZXRoaW5n'})
        adapter.spy.verify
      end

      it "should not store unknown asset types" do
        adapter.process({'key' => 'something.txt'})
        adapter.spy.verify
      end
    end
  end
end