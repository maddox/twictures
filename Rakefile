require 'rubygems'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Default task is to run specs"
task :default => :test

namespace :twicture do
  task :init do
    require File.join(File.join(File.dirname(__FILE__), 'lib'), 'twicture')
  end
end
