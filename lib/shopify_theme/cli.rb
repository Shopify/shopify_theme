require 'thor'
require 'yaml'
YAML::ENGINE.yamler = 'syck' if defined? Syck
require 'abbrev'
require 'base64'
require 'fileutils'
require 'json'
require 'filewatcher'
require 'launchy'

module ShopifyTheme
  class Cli < Thor
    include Thor::Actions

    BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff otf swf ico)
    IGNORE = %w(config.yml)
    DEFAULT_WHITELIST = %w(layout/ assets/ config/ snippets/ templates/)
    TIMEFORMAT = "%H:%M:%S"

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    desc "check", "check configuration"
    def check
      if ShopifyTheme.check_config
        say("Configuration [OK]", :green)
      else
        say("Configuration [FAIL]", :red)
      end
    end

    desc "configure API_KEY PASSWORD STORE THEME_ID", "generate a config file for the store to connect to"
    def configure(api_key=nil, password=nil, store=nil, theme_id=nil)
      config = {:api_key => api_key, :password => password, :store => store, :theme_id => theme_id}
      create_file('config.yml', config.to_yaml)
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
    end

    desc "open", "open the store in your browser"
    def open(*keys)
      if Launchy.open shop_theme_url
        say("Done.", :green)
      end
    end

    desc "upload FILE", "upload all theme assets to shop"
    method_option :quiet, :type => :boolean, :default => false
    def upload(*keys)
      assets = keys.empty? ? local_assets_list : keys
      assets.each do |asset|
        send_asset(asset, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "replace FILE", "completely replace shop theme assets with local theme assets"
    method_option :quiet, :type => :boolean, :default => false
    def replace(*keys)
      say("Are you sure you want to completely replace your shop theme assets? This is not undoable.", :yellow)
      if ask("Continue? (Y/N): ") == "Y"
        # only delete files on remote that are not present locally
        # files present on remote and present locally get overridden anyway
        remote_assets = keys.empty? ? (ShopifyTheme.asset_list - local_assets_list) : keys
        remote_assets.each do |asset|
          delete_asset(asset, options['quiet'])
        end
        local_assets = keys.empty? ? local_assets_list : keys
        local_assets.each do |asset|
          send_asset(asset, options['quiet'])
        end
        say("Done.", :green) unless options['quiet']
      end
    end

    desc "remove FILE", "remove theme asset"
    method_option :quiet, :type => :boolean, :default => false
    def remove(*keys)
      keys.each do |key|
        delete_asset(key, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "watch", "upload and delete individual theme assets as they change, use the --keep_files flag to disable remote file deletion"
    method_option :quiet, :type => :boolean, :default => false
    method_option :keep_files, :type => :boolean, :default => false
    def watch
      puts "Watching current folder: #{Dir.pwd}"
      watcher do |filename, event|
        filename = filename.gsub("#{Dir.pwd}/", '')
        if local_assets_list.include?(filename)
          action = case event
          when :changed, :new then :send_asset
          when :delete then :delete_asset
          else raise NotImplementedError, "Unknown event -- #{event}"
          end
          send(action, filename, options['quiet'])
        end
      end
    end

    desc "systeminfo", "print out system information and actively loaded libraries for aiding in submitting bug reports"
    def systeminfo
      ruby_version = "#{RUBY_VERSION}"
      ruby_version += "-p#{RUBY_PATCHLEVEL}" if RUBY_PATCHLEVEL
      puts "Ruby: v#{ruby_version}"
      puts "Operating System: #{RUBY_PLATFORM}"
      %w(Thor Listen HTTParty Launchy).each do |lib|
        require "#{lib.downcase}/version"
        puts "#{lib}: v" +  Kernel.const_get("#{lib}::VERSION")
      end
    end

    protected

    def config
      @config ||= YAML.load_file 'config.yml'
    end

    def shop_theme_url
      url = config[:store]
      url += "?preview_theme_id=#{config[:theme_id]}" if config[:theme_id] && config[:theme_id].to_i > 0
      url
    end

    private

    def watcher
      FileWatcher.new(Dir.pwd).watch() do |filename, event|
        yield(filename, event)
      end
    end

    def local_assets_list
      local_files.reject do |p|
        @permitted_files ||= (DEFAULT_WHITELIST | ShopifyTheme.whitelist_files).map{|pattern| Regexp.new(pattern)}
        @permitted_files.none? { |regex| regex =~ p }
      end
    end

    def local_files
      Dir.glob(File.join('**', '*')).reject do |f|
        File.directory?(f)
      end
    end

    def download_asset(key)
      return unless valid?(key)
      notify_and_sleep("Approaching limit of API permits. Naptime until more permits become available!") if ShopifyTheme.needs_sleep?
      asset = ShopifyTheme.get_asset(key)
      if asset['value']
        # For CRLF line endings
        content = asset['value'].gsub("\r", "")
        format = "w"
      elsif asset['attachment']
        content = Base64.decode64(asset['attachment'])
        format = "w+b"
      end

      FileUtils.mkdir_p(File.dirname(key))
      File.open(key, format) {|f| f.write content} if content
    end

    def send_asset(asset, quiet=false)
      return unless valid?(asset)
      time = Time.now
      data = {:key => asset}
      content = File.read(asset)
      if BINARY_EXTENSIONS.include?(File.extname(asset).gsub('.','')) || ShopifyTheme.is_binary_data?(content)
        content = File.open(asset, "rb") { |io| io.read }
        data.merge!(:attachment => Base64.encode64(content))
      else
        data.merge!(:value => content)
      end

      response = ShopifyTheme.send_asset(data)
      if response.success?
        say("[" + time.strftime(TIMEFORMAT) + "] Uploaded: #{asset}", :green) unless quiet
      else
        report_error(time, "Could not upload #{asset}", response)
      end
    end

    def delete_asset(key, quiet=false)
      return unless valid?(key)
      time = Time.now
      if (response = ShopifyTheme.delete_asset(key)).success?
        say("[" + time.strftime(TIMEFORMAT) + "] Removed: #{key}", :green) unless quiet
      else
        report_error(time, "Could not remove #{key}", response)
      end
    end

    def notify_and_sleep(message)
      say(message, :red)
      ShopifyTheme.sleep
    end

    def valid?(key)
      return true if DEFAULT_WHITELIST.include?(key.split('/').first + "/")
      say("'#{key}' is not in a valid file for theme uploads", :yellow)
      say("Files need to be in one of the following subdirectories: #{DEFAULT_WHITELIST.join(' ')}", :yellow)
      false
    end

    def report_error(time, message, response)
      say("[#{time.strftime(TIMEFORMAT)}] Error: #{message}", :red)
      say("Error Details: #{errors_from_response(response)}", :yellow)
    end

    def errors_from_response(response)
      object = {status: response.headers['status'], request_id: response.headers['x-request-id']}

      errors = response.parsed_response ? response.parsed_response["errors"] : response.body

      object[:errors] = case errors
      when NilClass
        ''
      when String
        errors.strip
      else
        errors.values.join(", ")
      end
      object.delete(:errors) if object[:errors].length <= 0
      object
    end
  end
end
