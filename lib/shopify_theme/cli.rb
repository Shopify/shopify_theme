require 'thor'
require 'yaml'
YAML::ENGINE.yamler = 'syck' if defined? Syck
require 'abbrev'
require 'base64'
require 'fileutils'
require 'json'
require 'filewatcher'
require 'launchy'
require 'mimemagic'
require 'shopify_theme/file_filters'

module ShopifyTheme
  EXTENSIONS = [
    {mimetype: 'application/x-liquid', extensions: %w(liquid), parents: 'text/plain'},
    {mimetype: 'application/json', extensions: %w(json), parents: 'text/plain'},
    {mimetype: 'application/js', extensions: %w(map), parents: 'text/plain'},
    {mimetype: 'application/vnd.ms-fontobject', extensions: %w(eot)},
    {mimetype: 'image/svg+xml', extensions: %w(svg svgz)}
  ]

  def self.configureMimeMagic
    ShopifyTheme::EXTENSIONS.each do |extension|
      MimeMagic.add(extension.delete(:mimetype), extension)
    end
  end

  class Cli < Thor
    include Thor::Actions

    IGNORE = %w(config.yml)
    DEFAULT_WHITELIST = %w(layout/ assets/ config/ snippets/ templates/ locales/ sections/)
    TIMEFORMAT = "%H:%M:%S"

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    desc "check", "check configuration"
    def check(exit_on_failure=false)
      result = APIChecker.new(ShopifyTheme).test_connectivity

      if result.api_down?
        say("Cannot connect to Shopify. API appears to be down", :red)
        say("Visit http://status.shopify.com for more details", :yello)
      elsif result.invalid_config?
        say("Cannot connect to Shopify. Configuration is invalid.", :red)
        say("Verify that your API key, password and domain are correct.", :yellow)
        say("Visit https://github.com/shopify/shopify_theme#configuration for more details", :yellow)
        say("If your shop domain is correct, the following URL should take you to the Private Apps page for the shop:", :yellow)
        say("  https://#{config[:store]}/admin/apps/private", :yellow)
      else
        say("Shopify API is accessible and configuration is valid", :green) unless exit_on_failure
      end

      exit(1) if result.cannot_access_api? && exit_on_failure
    end

    desc "configure API_KEY PASSWORD STORE THEME_ID", "generate a config file for the store to connect to"
    def configure(api_key=nil, password=nil, store=nil, theme_id=nil)
      config = {:api_key => api_key, :password => password, :store => store, :theme_id => theme_id, :whitelist_files => Filters::Whitelist::DEFAULT_WHITELIST}
      create_file('config.yml', config.to_yaml)
      check(true)
    end

    desc "configure_oauth ACCESS_TOKEN STORE THEME_ID", "generate a config file for the store to connect to using an OAuth access token"
    def configure_oauth(access_token=nil, store=nil, theme_id=nil)
      config = {:access_token => access_token, :store => store, :theme_id => theme_id}
      create_file('config.yml', config.to_yaml)
    end

    desc "bootstrap API_KEY PASSWORD STORE THEME_NAME", "bootstrap with Timber to shop and configure local directory."
    method_option :master, :type => :boolean, :default => false
    method_option :version, :type => :string, :default => "latest"
    def bootstrap(api_key=nil, password=nil, store=nil, theme_name=nil)
      ShopifyTheme.config = {:api_key => api_key, :password => password, :store => store, :whitelist_files => Filters::Whitelist::DEFAULT_WHITELIST}
      check(true)

      theme_name ||= 'Timber'
      say("Registering #{theme_name} theme on #{store}", :green)
      theme = ShopifyTheme.upload_timber(theme_name, options[:version])

      say("Creating directory named #{theme_name}", :green)
      empty_directory(theme_name)

      say("Saving configuration to #{theme_name}", :green)
      ShopifyTheme.config.merge!(theme_id: theme['id'])
      create_file("#{theme_name}/config.yml", ShopifyTheme.config.to_yaml)

      say("Downloading #{theme_name} assets from Shopify")
      Dir.chdir(theme_name)
      download()
    rescue Releases::VersionError => e
      say(e.message, :red)
    end

    desc "download FILE", "download the shops current theme assets"
    method_option :quiet, :type => :boolean, :default => false
    method_option :exclude
    def download(*keys)
      check(true)
      assets = assets_for(keys, ShopifyTheme.asset_list)

      if options['exclude']
        assets = assets.delete_if { |asset| asset =~ Regexp.new(options['exclude']) }
      end

      assets.each do |asset|
        download_asset(asset)
        say("#{ShopifyTheme.api_usage} Downloaded: #{asset}", :green) unless options['quiet']
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
      check(true)
      assets = assets_for(keys, local_assets_list)
      assets = keys.empty? ? local_assets_list : keys
      assets.each do |asset|
        send_asset(asset, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "replace FILE", "completely replace shop theme assets with local theme assets"
    method_option :quiet, :type => :boolean, :default => false
    def replace(*keys)
      check(true)
      say("Are you sure you want to completely replace your shop theme assets? This is not undoable.", :yellow)
      if ask("Continue? (Y/N): ") == "Y"
        # only delete files on remote that are not present locally
        # files present on remote and present locally get overridden anyway
        remote_assets = keys.empty? ? (ShopifyTheme.asset_list - local_assets_list) : keys
        remote_assets.each do |asset|
          delete_asset(asset, options['quiet']) unless ShopifyTheme.ignore_files.any? { |regex| regex =~ asset }
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
      check(true)
      keys.each do |key|
        delete_asset(key, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "watch", "upload and delete individual theme assets as they change, use the --keep_files flag to disable remote file deletion"
    method_option :quiet, :type => :boolean, :default => false
    method_option :keep_files, :type => :boolean, :default => false
    def watch
      check(true)
      puts "Watching current folder: #{Dir.pwd}"
      watcher do |filename, event|
        filename = filename.gsub("#{Dir.pwd}/", '')
        
        next unless local_assets_list.include?(filename)
        
        action = if [:changed, :new].include?(event)
          :send_asset
        elsif event == :delete && !options['keep_files']
          :delete_asset
        else
          raise NotImplementedError, "Unknown event -- #{event} -- #{filename}"
        end

        send(action, filename, options['quiet'])
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

    no_commands do
      def local_assets_list
        FileFilters.new(
          Filters::Whitelist.new(ShopifyTheme.whitelist_files),
          Filters::Blacklist.new(ShopifyTheme.ignore_files)
        ).select(local_files)
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
    def assets_for(keys=[], files=[])
      filter = FileFilters.new(Filters::CommandInput.new(keys))
      filter.select(files)
    end

    def watcher
      FileWatcher.new(Dir.pwd).watch() do |filename, event|
        yield(filename, event)
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
      data = {:key => asset}
      content = File.read(asset)
      if binary_file?(asset) || ShopifyTheme.is_binary_data?(content)
        content = File.open(asset, "rb") { |io| io.read }
        data.merge!(:attachment => Base64.encode64(content))
      else
        data.merge!(:value => content)
      end

      response = show_during("[#{timestamp}] Uploading: #{asset}", quiet) do
        ShopifyTheme.send_asset(data)
      end
      if response.success?
        say("[#{timestamp}] Uploaded: #{asset}", :green) unless quiet
      else
        report_error(Time.now, "Could not upload #{asset}", response)
      end
    end

    def delete_asset(key, quiet=false)
      return unless valid?(key)
      response = show_during("[#{timestamp}] Removing: #{key}", quiet) do
        ShopifyTheme.delete_asset(key)
      end
      if response.success?
        say("[#{timestamp}] Removed: #{key}", :green) unless quiet
      else
        report_error(Time.now, "Could not remove #{key}", response)
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

    def binary_file?(path)
      mime = MimeMagic.by_path(path)
      say("'#{path}' is an unknown file-type, uploading asset as binary", :yellow) if mime.nil? && ENV['TEST'] != 'true'
      mime.nil? || !mime.text?
    end

    def report_error(time, message, response)
      say("[#{timestamp(time)}] Error: #{message}", :red)
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

    def show_during(message = '', quiet = false, &block)
      print(message) unless quiet
      result = yield
      print("\r#{' ' * message.length}\r") unless quiet
      result
    end

    def timestamp(time = Time.now)
      time.strftime(TIMEFORMAT)
    end
  end
end
ShopifyTheme.configureMimeMagic
