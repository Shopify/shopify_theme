require 'rubygems'
require 'thor'
require 'yaml'
require 'abbrev'
require 'httparty'
require 'base64'
require 'ftools'
require 'json'

module ShopifyTheme
  class Cli < Thor
    include Thor::Actions

    BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff swf)
    IGNORE = %w(config.yml)

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    desc "configure API_KEY PASSWORD STORE", "generate a config file for the store to connect to"
    def generate(api_key=nil, password=nil, store=nil)
      config = {:api_key => api_key, :password => password, :store => store}
      create_file('config.yml', config.to_yaml)
    end

    desc "download", "download the shops current theme"
    def download
      setup
      asset_list.each do |a|
        asset = get_asset(a)

        if asset['value']
          content = asset['value'].gsub("\r", "")
        elsif asset['attachment']
          content = Base64.decode64(asset['attachment'])
        end

        File.makedirs(File.dirname(a))
        File.open(a, "w") {|f| f.write content} if content
        print "."
        $stdout.flush
      end
      puts "\nDone."
    end

    desc "upload", "upload all theme files to shop"
    def upload
      setup

      local_assets_list.each do |a|
        send_asset(a)
      end
      puts "Done."
    end

    desc "watch", "upload individual files as they change"
    method_option :quiet, :type => :boolean, :default => false
    def watch
      setup

      loop do
        modified_files.each do |a|
          send_asset(a, options['quiet'])
        end
        sleep(1)
      end
    rescue Interrupt
      puts ""
    end

    private
    def setup
      @config = YAML.load(File.read('config.yml'))
      @default_options = {:basic_auth => {:username => @config[:api_key], :password => @config[:password]}}
      @base_uri = "http://#{@config[:store]}"
    end

    def asset_list
      response = HTTParty.get("#{@base_uri}/admin/assets.json", @default_options)
      assets = JSON.parse(response.body)["assets"].collect {|a| a['key'] }
      # Remove any .css files if a .css.liquid file exists
      assets.reject{|a| assets.include?("#{a}.liquid") }
    end

    def get_asset(asset)
      response = HTTParty.get("#{@base_uri}/admin/assets.json", @default_options.merge(:query =>{:asset => {:key => asset}}))
      # HTTParty json parsing is broken?
      JSON.parse(response.body)["asset"]
    end

    def local_assets_list
      Dir.glob(File.join("**", "*")).reject{ |p| File.directory?(p) || IGNORE.include?(p)}
    end

    def send_asset(asset, quiet=false)
      data = {:key => asset}
      if (content = File.read(asset)).is_binary_data? || BINARY_EXTENSIONS.include?(File.extname(asset).gsub('.',''))
        data.merge!(:attachment => Base64.encode64(content))
      else
        data.merge!(:value => content)
      end

      response = HTTParty.put("#{@base_uri}/admin/assets.json", @default_options.merge(:body =>{:asset => data}))

      if response.success?
        puts "Uploaded: #{asset}" unless quiet
      else
        puts "Error: Could not upload #{asset} to #{@config['store']}"
      end
    end

    def modified_files
      @reference_time ||= Time.now
      checked = Time.now

      files = local_assets_list.select do |asset|
        File.mtime(asset) > @reference_time
      end
      @reference_time = checked unless files.empty?
      files
    end
  end
end
