require 'bundler'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

Rake::TestTask.new 'spec' do |t|
  t.libs = ['lib', 'spec']
  t.ruby_opts << '-rubygems'
  t.verbose = true
  t.test_files = FileList['spec/**/*_spec.rb']
end

