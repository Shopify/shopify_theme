require 'bundler'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'shopify_theme'

task :default => [:spec]

Rake::TestTask.new 'spec' do |t|
  ENV['test'] = 'true'
  t.libs = ['lib', 'spec']
  t.ruby_opts << '-rubygems'
  t.verbose = true
  t.test_files = FileList['spec/**/*_spec.rb']
end

desc "Update the built-in CA root certificate file"
task :update_cert_file do
  require 'net/http'
  require 'uri'
  cert_uri = URI(ShopifyTheme::REMOTE_CERT_FILE)
  response = Net::HTTP.get_response(cert_uri)
  if response.code == '200'
    File.open(ShopifyTheme::CA_CERT_FILE, 'wb') { |cert_file| cert_file << response.body }
  else
    fail "Could not download certificate bundle from #{cert_uri}"
  end
end

