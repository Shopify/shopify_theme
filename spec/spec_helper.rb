ENV['TEST'] = 'true'
require 'minitest/autorun'
require 'webmock'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
end
