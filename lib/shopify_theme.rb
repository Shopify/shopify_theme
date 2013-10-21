require 'httparty'
module ShopifyTheme
  include HTTParty

  NOOPParser = Proc.new {|data, format| {} }

  def self.asset_list
    # HTTParty parser chokes on assest listing, have it noop
    # and then use a rel JSON parser.
    response = shopify.get(path, :parser => NOOPParser)
    assets = JSON.parse(response.body)["assets"].collect {|a| a['key'] }
    # Remove any .css files if a .css.liquid file exists
    assets.reject{|a| assets.include?("#{a}.liquid") }
  end

  def self.get_asset(asset)
    response = shopify.get(path, :query =>{:asset => {:key => asset}}, :parser => NOOPParser)
    # HTTParty json parsing is broken?
    JSON.parse(response.body)["asset"]
  end

  def self.send_asset(data)
    shopify.put(path, :body =>{:asset => data})
  end

  def self.delete_asset(asset)
    shopify.delete(path, :body =>{:asset => {:key => asset}})
  end

  def self.config
    if File.exist? 'config.yml'
      @config ||= YAML.load(File.read('config.yml'))
      puts ":ignore_files: is deprecated for a white list, use :whitelist_files: instead" if @config[:ignore_files]
    else
      puts "config.yml does not exist!"
      {}
    end
  end

  def self.path
    @path ||= config[:theme_id] ? "/admin/themes/#{config[:theme_id]}/assets.json" : "/admin/assets.json"
  end

  def self.ignore_files
    @ignore_files ||= (config[:ignore_files] || []).compact.map { |r| Regexp.new(r) }
  end

  def self.whitelist_files
    @whitelist_files ||= (config[:whitelist_files] || []).compact
  end

  def self.is_binary_data?(string)
    if string.respond_to?(:encoding)
      string.encoding == "US-ASCII"
    else
      ( string.count( "^ -~", "^\r\n" ).fdiv(string.size) > 0.3 || string.index( "\x00" ) ) unless string.empty?
    end
  end

  def self.check_config
    shopify.get(path).code == 200
  end

  private
  def self.shopify
    basic_auth config[:api_key], config[:password]
    base_uri "https://#{config[:store]}"
    ShopifyTheme
  end
end
