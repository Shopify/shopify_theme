require 'bundler'
require 'rake/testtask'

task :default => [:spec]

Rake::TestTask.new 'spec' do |t|
  ENV['test'] = 'true'
  t.libs = ['lib', 'spec']
  t.ruby_opts << '-rubygems'
  t.verbose = true
  t.test_files = FileList['spec/**/*_spec.rb']
end

