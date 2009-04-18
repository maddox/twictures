require File.dirname(__FILE__) + "/../lib/twicture/app"

class Twicture::App
  set :run, false
  set :env, ENV['APP_ENV'] || :production
  run!
end
