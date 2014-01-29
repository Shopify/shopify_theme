require 'httparty'
module ShopifyTheme
  include HTTParty
  @@current_api_call_count = 0
  @@total_api_calls = 40

  NOOPParser = Proc.new {|data, format| {} }
  TIMER_RESET = 10
  PERMIT_LOWER_LIMIT = 3

  def self.test?
    ENV['test']
  end

  def self.manage_timer(response)
    return unless response.headers['x-shopify-shop-api-call-limit']
    @@current_api_call_count, @@total_api_calls = response.headers['x-shopify-shop-api-call-limit'].split('/')
    @@current_timer = Time.now if @current_timer.nil?
  end

  def self.critical_permits?
    @@total_api_calls.to_i - @@current_api_call_count.to_i < PERMIT_LOWER_LIMIT
  end

  def self.passed_api_refresh?
    delta_seconds > TIMER_RESET
  end

  def self.delta_seconds
    Time.now.to_i - @@current_timer.to_i
  end

  def self.needs_sleep?
    critical_permits? && !passed_api_refresh?
  end

  def self.sleep
    if needs_sleep?
      Kernel.sleep(TIMER_RESET - delta_seconds)
      @current_timer = nil
    end
  end

  def self.api_usage
    "[API Limit: #{@@current_api_call_count || "??"}/#{@@total_api_calls || "??"}]"
  end


  def self.asset_list
    # HTTParty parser chokes on assest listing, have it noop
    # and then use a rel JSON parser.
    response = shopify.get(path, :parser => NOOPParser)
    manage_timer(response)

    assets = JSON.parse(response.body)["assets"].collect {|a| a['key'] }
    # Remove any .css files if a .css.liquid file exists
    assets.reject{|a| assets.include?("#{a}.liquid") }
  end

  def self.get_asset(asset)
    response = shopify.get(path, :query =>{:asset => {:key => asset}}, :parser => NOOPParser)
    manage_timer(response)

    # HTTParty json parsing is broken?
    asset = response.code == 200 ? JSON.parse(response.body)["asset"] : {}
    asset['response'] = response
    asset
  end

  def self.send_asset(data)
    response = shopify.put(path, :body =>{:asset => data})
    manage_timer(response)
    response
  end

  def self.delete_asset(asset)
    response = shopify.delete(path, :body =>{:asset => {:key => asset}})
    manage_timer(response)
    response
  end

  def self.config
    @config ||= if File.exist? 'config.yml'
      config = YAML.load(File.read('config.yml'))
      puts ":ignore_files: is deprecated for a white list, use :whitelist_files: instead" if config[:ignore_files] && !test?
      config
    else
      puts "config.yml does not exist!" unless test?
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
