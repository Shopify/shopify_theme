# Requirements

Ruby 1.9

# Installation

````
gem install shopify_theme [optional_theme_id]
````

# Usage

Generate the config file. Go get a valid api_key and password for your store head to https://[your store].myshopify.com/admin/apps/private and generate a private application. Default it adds the main theme, if you want to edit one of your other themes, add the theme_id.

````
theme configure api_key password store_url
````

Example of config.yml. Notice store has no http or https declaration. You can
use `:whitelist_files:` to specify files for upload. The `assets/`, `config/`,
`layout/`, `snippets/` and `templates/` directories are included by default.

````
---
:api_key: 7a8da86d3dd730b67a357dedabaac5d6
:password: 552338ce0d3aba7fc501dcf99bc57a81
:store: little-plastics.myshopify.com
:theme_id:
:whitelist_files:
- directoryToUpload/
- importantFile.txt
````

Download all the theme files

````
theme download
````

Upload a theme file

````
theme upload assets/layout.liquid
````

Remove a theme file

````
theme remove assets/layout.liquid
````

Completely replace shop theme assets with the local assets

````
theme replace
````

Watch the theme directory and upload any files as they change

````
theme watch
````

Open the store in the default browser

````
theme open
````

# Common Problems

### During the installation of the gem or when trying to use the gem I am encountering the following error

`Unable to activate httparty-0.12.0, because json-1.5.4 conflicts with json (~> 1.8) (Gem::LoadError)
    from /Users/Luke/.rvm/rubies/ruby-1.9.3-p374/lib/ruby/site_ruby/1.9.1/rubygems/specification.rb:747:in `activate'`

Your globally installed JSON gem is a newer version than what is required for `shopify_theme`. You can get around this
problem by creating a Gemfile in your theme folder as follows:

```ruby
source 'https://rubygems.org'

gem 'shopify_theme'
```