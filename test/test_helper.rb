$LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/../lib")

require 'ostruct'
require 'test/unit'

# require 'rubygems'
# gem 'jeremymcanally-matchy'
# gem 'jeremymcanally-context'
# gem 'rr'

# require File.join(File.dirname(__FILE__), '..', 'lib', 'my_app')
# require 'context'
# require 'matchy'
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

module MyApp
  class TestCase < Test::Unit::TestCase
    # include RR::Adapters::TestUnit
  end
end
