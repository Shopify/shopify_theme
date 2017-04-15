require 'rubygems'
require 'rubygems/command'
require 'rubygems/dependency_installer'

module ShopifyTheme
  module Ext
    class PlatformInstaller
      PLATFORMS_WITH_DEPENDENCIES = [:windows]

      def self.run
        PlatformInstaller.new.run
      end

      def initialize
        begin
          Gem::Command.build_args = ARGV
        rescue NoMethodError
        end
      end

      def run
        return unless platform_specific_dependencies?
        install_platform_dependencies
        indicate_success
      end

      private

      def platform_specific_dependencies?
        PLATFORMS_WITH_DEPENDENCIES.include? determine_platform
      end

      def determine_platform(platform=RUBY_PLATFORM)
        if platform =~ /mswin|mingw/i
          :windows
        else
          nil
        end
      end

      def install_platform_dependencies
        installer = Gem::DependencyInstaller.new
        platform = determine_platform
        if platform == :windows
          installer.install "wdm"
        end
      rescue => e
        log_error_and_quit(e)
      end

      def indicate_success
        File.open(File.join(File.dirname(__FILE__), "Rakefile"), 'wb') do |f|
          f.puts "task :default"
        end
      end

      def log_error_and_quit(e)
        puts "Could not install shopify_theme for #{RUBY_PLATFORM}"
        puts "Create a ticket on https://github.com/shopify/shopify_theme/issues with the following information"
        puts e.message
        exit(1)
      end

    end
  end
end

ShopifyTheme::Ext::PlatformInstaller.run