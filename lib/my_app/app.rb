require 'sinatra/base'

if !Object.const_defined?(:MyApp)
  require File.join(File.dirname(__FILE__), '..', 'my_app')
end

class MyApp::App < Sinatra::Base
end
