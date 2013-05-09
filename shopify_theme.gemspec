# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "shopify_theme/version"

Gem::Specification.new do |s|
  s.name        = "shopify_theme"
  s.version     = ShopifyTheme::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John Duff"]
  s.email       = ["john.duff@shopify.com"]
  s.homepage    = "https://github.com/Shopify/shopify_theme"
  s.summary     = %q{Command line tool for developing themes}
  s.description = %q{Command line tool to help with developing Shopify themes. Provides simple commands to download, upload and delete files from a theme. Also includes the watch command to watch a directory and upload files as they change.}

  s.rubyforge_project = "shopify_theme"
  s.add_dependency("thor", [">= 0.14.4"])
  s.add_dependency("httparty", [">= 0.8.0"])
  s.add_dependency("json")
  s.add_dependency("listen", [">= 1.0.3"])

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
