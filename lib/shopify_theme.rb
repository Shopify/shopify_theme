require 'httparty'
module ShopifyTheme
  include HTTParty

  def self.asset_list
    response = shopify.get("/admin/assets.json")
    assets = JSON.parse(response.body)["assets"].collect {|a| a['key'] }
    # Remove any .css files if a .css.liquid file exists
    assets.reject{|a| assets.include?("#{a}.liquid") }
  end

  def self.get_asset(asset)
    response = shopify.get("/admin/assets.json", :query =>{:asset => {:key => asset}})
    # HTTParty json parsing is broken?
    JSON.parse(response.body)["asset"]
  end

  def self.send_asset(data)
    shopify.put("/admin/assets.json", :body =>{:asset => data})
  end

  def self.delete_asset(asset)
    shopify.delete("/admin/assets.json", :body =>{:asset => {:key => asset}})
  end

  def self.config
    @config ||= YAML.load(File.read('config.yml'))
  end

  def self.ignore_files
    @ignore_files ||= (config[:ignore_files] || []).compact.collect { |r| Regexp.new(r) }
  end

  private
  def self.shopify
    basic_auth config[:api_key], config[:password]
    base_uri "http://#{config[:store]}"
    ShopifyTheme
  end
end
