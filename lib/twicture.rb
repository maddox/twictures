$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'vendor', 'attachment_fu', 'lib')

require 'active_record'
require 'attachment_fu'
require 'attachment_fu/tasks'
require 'open-uri'
require 'json'
require 'RMagick'

ActiveRecord::Base.establish_connection \
  :adapter => 'mysql',
  :host => 'localhost',
  :database => "twictures_#{ENV['ENV'] || 'development'}",
  :username => 'twictures',
  :password => ''

AttachmentFu.setup ActiveRecord::Base
AttachmentFu.reset
AttachmentFu.root_path = File.join(File.dirname(__FILE__), '..', 'public')

module Twicture
  class Status < ActiveRecord::Base
    set_table_name 'twicture_statuses'

    is_attachment :path => 'i'

    before_validation_on_create :store_parsed_data
    before_create :create_temporary_image

    def twitter_data
      @twitter_data ||= JSON.parse(open(twitter_json_url).read)
    end

    def twitter_json_url
      @twitter_json_url ||= "http://twitter.com/statuses/show/#{status}.json"
    end

    def twitter_url
      "http://twitter.com/#{screen_name}/statuses/#{status}"
    end

  private
    def generate_image
      imagelist = Magick::ImageList.new
      imagelist.new_image(1, 10) { self.background_color = '#0080FF' }
      imagelist.read("caption:#{text}") do
        self.size = "400x"
        self.pointsize = 24
        # self.font = 'DejaVu Sans'
        self.antialias = true
      end
      imagelist[1].border!(10,10,'#ffffff')
      imagelist[1].border!(10,0,'#0080FF')
      imagelist.new_image(1, 40) { self.background_color = '#0080FF' }
      image = imagelist.append(true)

      out = Magick::Draw.new
      out.font = 'DejaVu Sans'
      out.pointsize = 20
      out.font_weight = 600
      out.fill = '#FFFF'
      out.gravity = Magick::SouthWestGravity
      out.text_antialias = true
      out.annotate(image, 0, 0, 10, 10, "#{screen_name}")

      out.pointsize = 14
      out.fill = '#ffffff'
      out.gravity = Magick::SouthEastGravity
      twictures_text = (rand(5) == 0) ? 'donate @ http://twictur.es' : 'http://twictur.es'
      out.annotate(image, 0, 0, 10, 10, twictures_text)
      image.format = 'GIF'
      image
    end

    # dont add the 0000/0001 id partitioned path
    def partitioned_path(*args)
      args
    end

    def create_temporary_image
      set_temp_data(filename, generate_image.to_blob)
    end

    def store_parsed_data
      self.filename     = "#{status}.gif"
      self.screen_name  = twitter_data['user']['screen_name']
      self.text         = twitter_data['text']
      self.content_type = 'image/gif'
    end
  end
end

if !Twicture::Status.table_exists?
  require 'twicture/schema'
end
