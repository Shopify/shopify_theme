require 'thor'
require 'yaml'
require 'abbrev'
require 'base64'
require 'fileutils'
require 'json'
require 'fssm'

module ShopifyTheme
  class Cli < Thor
    include Thor::Actions

    BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff swf)
    IGNORE = %w(config.yml)

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    desc "configure API_KEY PASSWORD STORE", "generate a config file for the store to connect to"
    def configure(api_key=nil, password=nil, store=nil)
      config = {:api_key => api_key, :password => password, :store => store}
      create_file('config.yml', config.to_yaml)
    end

    desc "download FILE", "download the shops current theme assets"
    method_option :quiet, :type => :boolean, :default => false
    def download(*keys)
      assets = keys.empty? ? ShopifyParty.asset_list : keys

      assets.each do |asset|
        download_asset(asset)
        puts "Downloaded: #{asset}" unless options['quiet']
      end
      puts "\nDone." unless options['quiet']
    end

    desc "upload FILE", "upload all theme assets to shop"
    method_option :quiet, :type => :boolean, :default => false
    def upload(*keys)
      assets = keys.empty? ? local_assets_list : keys
      assets.each do |a|
        send_asset(a, options['quiet'])
      end
      puts "Done." unless options['quiet']
    end

    desc "remove FILE", "remove theme asset"
    method_option :quiet, :type => :boolean, :default => false
    def remove(*keys)
      keys.each do |key|
        if ShopifyParty.delete_asset(key).success?
          puts "Removed: #{key}" unless options['quiet']
        else
          puts "Error: Could not remove #{key} from #{@config['store']}"
        end
      end
      puts "Done." unless options['quiet']
    end

    desc "watch", "upload individual theme assets as they change"
    method_option :quiet, :type => :boolean, :default => false
    def watch
      FSSM.monitor '.' do |m|
        m.update do |base, relative|
          send_asset(relative, options['quiet']) if local_assets_list.include?(relative)
        end
        m.create do |base, relative|
          send_asset(relative, options['quiet']) if local_assets_list.include?(relative)
        end
      end
    end

    private

    def local_assets_list
      Dir.glob(File.join("**", "*")).reject{ |p| File.directory?(p) || IGNORE.include?(p)}
    end

    def download_asset(key)
      asset = ShopifyParty.get_asset(key)
      if asset['value']
        # For CRLF line endings
        content = asset['value'].gsub("\r", "")
      elsif asset['attachment']
        content = Base64.decode64(asset['attachment'])
      end

      FileUtils.mkdir_p(File.dirname(key))
      File.open(key, "w") {|f| f.write content} if content
    end

    def send_asset(asset, quiet=false)
      data = {:key => asset}
      if (content = File.read(asset)).is_binary_data? || BINARY_EXTENSIONS.include?(File.extname(asset).gsub('.',''))
        data.merge!(:attachment => Base64.encode64(content))
      else
        data.merge!(:value => content)
      end

      if ShopifyParty.send_asset(data).success?
        puts "Uploaded: #{asset}" unless quiet
      else
        puts "Error: Could not upload #{asset} to #{@config['store']}"
      end
    end
  end
end
