require 'httparty'
module ShopifyTheme
  class ResponseError < StandardError; end

  include HTTParty
  @@current_api_call_count = 0
  @@total_api_calls = 40

  NOOPParser = Proc.new {|data, format| {} }
  TIMER_RESET = 10
  PERMIT_LOWER_LIMIT = 3
  TIMBER_ZIP = "https://github.com/Shopify/Timber/archive/%s.zip"
  LAST_KNOWN_STABLE = "v1.1.0"

  def self.test?
    ENV['test']
  end

  def self.manage_timer(response)
    return unless response.headers['x-shopify-shop-api-call-limit']
    @@current_api_call_count, @@total_api_calls = response.headers['x-shopify-shop-api-call-limit'].split('/')
    @@current_timer = Time.now if @current_timer.nil?
  end

  def self.raise_for_error(response)
    if (code = response.code) > 399
      raise ResponseError, "[HTTP #{code}] Invalid Request or Response\nResponse Body:\n#{response.body}"
    end
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
    raise_for_error(response)

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

  def self.upload_timber(name, master)
    source = TIMBER_ZIP % (master ? 'master' : LAST_KNOWN_STABLE)
    puts master ? "Using latest build from shopify" : "Using last known stable build -- #{LAST_KNOWN_STABLE}"
    response = shopify.post("/admin/themes.json", :body => {:theme => {:name => name, :src => source, :role => 'unpublished'}})
    manage_timer(response)
    body = JSON.parse(response.body)
    if theme = body['theme']
      watch_until_processing_complete(theme)
    else
      puts "Could not download theme!"
      puts body
      exit 1
    end
  end

  def self.config
    @config ||= if File.exist? 'config.yml'
      config = YAML.load(File.read('config.yml'))
      config
    else
      puts "config.yml does not exist!" unless test?
      {}
    end
  end

  def self.config=(config)
    @config = config
  end

  def self.path
    @path ||= config[:theme_id] ? "/admin/themes/#{config[:theme_id]}/assets.json" : "/admin/assets.json"
  end

  def self.ignore_files
    (config[:ignore_files] || []).compact.map { |r| Regexp.new(r) }
  end

  def self.whitelist_files
    (config[:whitelist_files] || []).compact
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

  def self.watch_until_processing_complete(theme)
    count = 0
    while true do
      Kernel.sleep(count)
      response = shopify.get("/admin/themes/#{theme['id']}.json")
      theme = JSON.parse(response.body)['theme']
      return theme if theme['previewable']
      count += 5
    end
  end
end
