$LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/../lib")

require 'test/unit'

require 'rubygems'
require 'sinatra/test'
gem 'jeremymcanally-matchy'
gem 'jeremymcanally-context'
# gem 'rr'

require File.join(File.dirname(__FILE__), '..', 'lib', 'my_app')
require 'context'
require 'matchy'
# require 'rr'
require 'logger'
require 'ruby-debug'
Debugger.start

FileUtils.mkdir_p File.join(File.dirname(__FILE__), '..', 'log')

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
  # poo
end

class Test::Unit::TestCase
  include Sinatra::Test
  # include RR::Adapters::TestUnit
  def test_truth
    assert false
  end
end
