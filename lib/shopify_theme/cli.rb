require 'thor'
require 'yaml'
require 'abbrev'
require 'base64'
require 'fileutils'
require 'json'
require 'listen'
require 'terminal-notifier'

module ShopifyTheme
  class Cli < Thor
    include Thor::Actions

    BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff swf)
    IGNORE = %w(config.yml)

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    desc "configure API_KEY PASSWORD STORE THEME_ID", "generate a config file for the store to connect to"
    def configure(api_key=nil, password=nil, store=nil, theme_id=nil)
      config = {:api_key => api_key, :password => password, :store => store, :theme_id => theme_id, :ignore_files => ["README"]}
      create_file('config.yml', config.to_yaml)
      TerminalNotifier.notify("Config file created", :title => "Shopify Theme")
    end

    desc "download FILE", "download the shops current theme assets"
    method_option :quiet, :type => :boolean, :default => false
    def download(*keys)
      assets = keys.empty? ? ShopifyTheme.asset_list : keys

      assets.each do |asset|
        download_asset(asset)
        say("Downloaded: #{asset}", :green) unless options['quiet']
      end
      say("Done.", :green) unless options['quiet']
      TerminalNotifier.notify("Finished downloading theme.", :title => "Shopify Theme")
    end

    desc "upload FILE", "upload all theme assets to shop"
    method_option :quiet, :type => :boolean, :default => false
    def upload(*keys)
      assets = keys.empty? ? local_assets_list : keys
      assets.each do |asset|
        send_asset(asset, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
      TerminalNotifier.notify("Finished uploading all theme assets", :title => "Shopify Theme")
    end

    desc "replace FILE", "completely replace shop theme assets with local theme assets"
    method_option :quiet, :type => :boolean, :default => false
    def replace(*keys)
	    say("Are you sure you want to completely replace your shop theme assets? This is not undoable.", :yellow)
	    if ask("Continue? (Y/N): ") == "Y"
		    remote_assets = keys.empty? ? ShopifyTheme.asset_list : keys
	      remote_assets.each do |asset|
	        delete_asset(asset, options['quiet'])
	      end
	      local_assets = keys.empty? ? local_assets_list : keys
	      local_assets.each do |asset|
	        send_asset(asset, options['quiet'])
	      end
	      say("Done.", :green) unless options['quiet']
	            TerminalNotifier.notify("Finished replacing all theme assets with local theme assets", :title => "Shopify Theme")
	      end
    end

    desc "remove FILE", "remove theme asset"
    method_option :quiet, :type => :boolean, :default => false
    def remove(*keys)
      keys.each do |key|
				delete_asset(key, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
	      TerminalNotifier.notify("Removed theme asset", :title => "Shopify Theme")
    end

    desc "watch", "upload and delete individual theme assets as they change, use the --keep_files flag to disable remote file deletion"
    method_option :quiet, :type => :boolean, :default => false
    method_option :keep_files, :type => :boolean, :default => false
    def watch
      puts "Watching current folder:"
      TerminalNotifier.notify("Started watching theme folder", :title => "Shopify Theme")
      Listen.to('',:relative_paths => true) do |modified, added, removed|
        modified.each do |filePath|
          send_asset(filePath, options['quiet']) if local_assets_list.include?(filePath)
        end
        added.each do |filePath|
          send_asset(filePath, options['quiet']) if local_assets_list.include?(filePath)
        end
        if !options['keep_files']
	        removed.each do |filePath|
	          delete_asset(filePath, options['quiet']) if local_assets_list.include?(relative)
	        end
        end
      end
    end
    
    private

    def local_assets_list
      Dir.glob(File.join("**", "*")).reject do |p|
        File.directory?(p) || IGNORE.include?(p) || ShopifyTheme.ignore_files.any? do |i|
          i =~ p
        end
      end
    end

    def download_asset(key)
      asset = ShopifyTheme.get_asset(key)
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
      content = File.read(asset)
      if ShopifyTheme.is_binary_data?(content) || BINARY_EXTENSIONS.include?(File.extname(asset).gsub('.',''))
        data.merge!(:attachment => Base64.encode64(content))
      else
        data.merge!(:value => content)
      end
	
      if (response = ShopifyTheme.send_asset(data)).success?
        say("Uploaded: #{asset}", :green) unless quiet
		TerminalNotifier.notify("#{asset} uploaded", :title => "Shopify Theme")
      else
        say("Error: Could not upload #{asset}. #{errors_from_response(response)}", :red)
		TerminalNotifier.notify("Error: Could not upload #{asset}. #{errors_from_response(response)}", :title => "Shopify Theme", :subtitle => 'Error')
      end
    end

    def delete_asset(key, quiet=false)
      if (response = ShopifyTheme.delete_asset(key)).success?
        say("Removed: #{key}", :green) unless quiet
        TerminalNotifier.notify("Removed: #{key}", :title => "Shopify Theme")
      else
        say("Error: Could not remove #{key}. #{errors_from_response(response)}", :red)
		TerminalNotifier.notify("Error: Could not remove #{key}. #{errors_from_response(response)}", :title => "Shopify Theme",:subtitle => 'Error')
      end
    end

    def errors_from_response(response)
      response.parsed_response ? response.parsed_response["errors"].values.join(", ") : ""
    end
  end
end
