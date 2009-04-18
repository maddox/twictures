require File.dirname(__FILE__) + "/../lib/my_app/app"

class MyApp::App
  set :run, false
  set :env, ENV['APP_ENV'] || :production
  run!
end