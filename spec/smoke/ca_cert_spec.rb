require 'spec_helper'
require 'shopify_theme'
require 'net/http'
require 'uri'
require 'digest'

module Smoke
  describe "CA Certificate Validity" do
    before do
      WebMock.disable!
      unless ENV['VERIFY_CERT']
        puts "Not testing CA certificates unless VERIFY_CERT variable is set"
        skip
      end
    end

    after do
      WebMock.enable!
    end

    it "verifies that the local certificate matches with that on haxx.se" do
      assert_equal digest(local_file), digest(remote_file)
    end

    def local_file
      File.read(ShopifyTheme::CA_CERT_FILE)
    end

    def remote_file
      cert_uri = URI(ShopifyTheme::REMOTE_CERT_FILE)
      response = Net::HTTP.get_response(cert_uri)
      if response.code == '200'
        response.body
      else
        flunk "Could not connect to #{cert_uri}. Verify that certificate is still hosted."
      end
    end

    def digest(message)
      Digest::MD5.hexdigest(message)
    end
  end
end
