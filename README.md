# Edit your Shopify theme locally

The Shopify theme gem is a command line tool that lets you make live changes to themes on your Shopify store. If the command line is scary, check out the [Desktop Theme Editor app](http://apps.shopify.com/desktop-theme-editor).

It will watch your local folders for any changes in your theme (including adding and removing files) and will update your .myshopify.com store to the latest changes. 

![Shopify theme gem](https://dl.dropboxusercontent.com/u/669627/terminalreadme.png)

You do not need to make changes to your default theme. You can leverage the theme preview feature of Shopify
that allows you to view what an unpublished theme looks like on your Shopify store. This means you don't need to
sign up for extra accounts and keep your shop up to date. You will however have a blue bar that shows up that you can
remove via the web inspector in Chrome or Safari.

# Requirements

This gem works with OS X or Windows with Ruby 1.9. 

First time installing Ruby on windows? Try [Rubyinstaller](http://http://rubyinstaller.org/). 

# Installation

To install the shopify_theme gem use 'gem install' (you might have use 'sudo gem install')

```
gem install shopify_theme [optional_theme_id]
```

to update to the latest version

```
gem update shopify_theme
```

# Usage

Generate the config file. Go get a valid api_key and password for your store head to `https://[your store].myshopify.com/admin/apps/private` and generate a private application. By default it adds the main theme, if you want to edit one of your other themes, add the `theme_id`.

```
theme configure api_key password store_url
```

Example of config.yml. Notice store has no http or https declaration. You can
use `:whitelist_files:` to specify files for upload. The `assets/`, `config/`,
`layout/`, `snippets/` and `templates/` directories are included by default.

You can also use `:ignore_files:` to exclude files from getting uploaded, for
example your `config/settings.html` or other configuration driven items

```yaml
---
:api_key: 7a8da86d3dd730b67a357dedabaac5d6
:password: 552338ce0d3aba7fc501dcf99bc57a81
:store: little-plastics.myshopify.com
:theme_id:
:whitelist_files:
- directoryToUpload/
- importantFile.txt
:ignore_files:
- config/settings.html
```

Download all the theme files

```
theme download
```

Upload a theme file

```
theme upload assets/layout.liquid
```

Remove a theme file

```
theme remove assets/layout.liquid
```

Completely replace shop theme assets with the local assets

```
theme replace
```

Watch the theme directory and upload any files as they change

```
theme watch
```

Open the store in the default browser

```
theme open
```

Bootstrap a new theme with [Timber](http://www.shopify.com/timber)

```
# use latest stable
theme bootstrap api_key password shop_name theme_name

# use latest build
theme bootstrap api_key password shop_name theme_name master
```

# Common Problems

## How do I edit a theme that isn't my shops main theme?

This can be done by setting the `theme_id` field in `config.yml` which was created when you
ran `theme configure`. Your file should look like the following:

```yaml
---
:api_key: 7a8da86d3dd730b67a357dedabaac5d6
:password: 552338ce0d3aba7fc501dcf99bc57a81
:store: little-plastics.myshopify.com
:theme_id: 0987654321
```

## Where can I find my Theme Id?

Currently the best way to find the id of the theme you want to edit is to go to the theme in your
shops admin and grab it from the url.

![themes/THEME_ID/settings](doc/how_to_find_theme_id.png)
