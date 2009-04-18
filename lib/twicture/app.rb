require 'sinatra/base'

if !Object.const_defined?(:Twicture)
  require File.join(File.dirname(__FILE__), '..', 'twicture')
end

class Twicture::App < Sinatra::Base
  get '/' do
    "hello"
  end

  get '/i/:twitter_status_id' do
    "<img src='/i/#{params[:twitter_status_id]}.gif' />"
  end
end
