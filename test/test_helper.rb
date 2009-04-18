$LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/../lib")

require 'test/unit'

require 'rubygems'
require 'sinatra/test'
gem 'jeremymcanally-matchy'
gem 'jeremymcanally-context'

ENV['ENV'] = 'test'
require File.join(File.dirname(__FILE__), '..', 'lib', 'twicture')
require 'twicture/app'
require 'twicture/schema'
require 'context'
require 'matchy'
require 'rr'
require 'fakeweb'
require 'logger'
require 'ruby-debug'
Debugger.start

files = File.join(File.dirname(__FILE__), 'public')
FileUtils.rm_rf   files
FileUtils.mkdir_p files
AttachmentFu.root_path = files

FileUtils.mkdir_p File.join(File.dirname(__FILE__), '..', 'log')

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
  # poo
end

class Test::Unit::TestCase
  include Sinatra::Test, RR::Adapters::TestUnit

  def self.register_fake_url(id, name)
    url  = "http://twitter.com/statuses/show/#{id}.json"
    data = {:user => {:name => name}, :text => 'foo', :id => id}
    FakeWeb.register_uri(:get, url, :string => data.to_json)
    [url, data]
  end
end
