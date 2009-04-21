require 'sinatra/base'

if !Object.const_defined?(:Twicture)
  require File.join(File.dirname(__FILE__), '..', 'twicture')
end

class Twicture::App < Sinatra::Base
  set :public, File.join(File.dirname(__FILE__), '..', '..', 'public')
  set :static, true

  get '/' do
    "hello"
  end

  get '/i/:status' do
    @tw = Twicture::Status.find_or_create_by_status(params[:status])
    "<img src='/i/#{@tw.status}.gif' />"
  end

  get '/r/:status' do
    @tw = Twicture::Status.find_or_create_by_status(params[:status])
    redirect @tw.twitter_url
  end
end
