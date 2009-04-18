$LOAD_PATH << File.dirname(__FILE__)

require 'active_record'
require 'open-uri'
require 'json'

ActiveRecord::Base.establish_connection \
  :adapter => 'mysql',
  :host => 'localhost',
  :database => "twictures_#{ENV['ENV'] || 'development'}",
  :username => 'twictures',
  :password => ''

module Twicture
  class Status < ActiveRecord::Base
    set_table_name 'twicture_statuses'

    before_validation_on_create :store_parsed_data

    def self.create_from_twitter(status_id)
      new(:status_id => status_id)
    end

    def twitter_data
      @twitter_data ||= JSON.parse(open(twitter_json_url).read)
    end

    def twitter_json_url
      @twitter_json_url ||= "http://twitter.com/statuses/show/#{status}.json"
    end

    def twitter_url
      "http://twitter.com/#{screen_name}/statuses/#{status}"
    end

  protected
    def store_parsed_data
      self.screen_name = twitter_data['user']['name']
      self.text        = twitter_data['text']
    end
  end
end

if !Twicture::Status.table_exists?
  require 'twicture/schema'
end
