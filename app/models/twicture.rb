class Twicture < ActiveRecord::Base
  include Magick
  
  before_create :get_twitter_data
  after_create :twicturlate
  
  def to_param
    status
  end
  
  def get_twitter_data
    #get twitter status id from url or status https://twitter.com/l4rk/statuses/939397539
    if !status && twitter_url.match(/^http(s)?:\/\/(www\.)?twitter.com\/\S+\/statuses\/(\d+)/)
      self.status =  $3
    else
      self.status ||= twitter_url
    end
    api_url = "http://twitter.com/statuses/show/#{status}.json"
    
    #pull tweet from twitter api
    begin
      #grab tweet and catch 403 forbidden errors
      tweet_json = open(api_url).read
    rescue
      return false
    end
    
    #parse from json and populate twicture data
    if tweet_json =~ /Twitter is down for maintenance/
      self.errors.add("Twitter", "is down")
      return false
    end
    tweet = JSON.parse(tweet_json)
    # tweet = {"user" => {"screen_name" => 'shayarnett'}}
    if tweet["user"] && tweet["text"]
      self.text = tweet["text"]
      self.image_path = "i/#{status.to_s}.gif"
      self.screen_name = tweet["user"]["screen_name"]
      self.twitter_url = "http://twitter.com/#{screen_name}/statuses/#{status}"
      return true
    else
      return false
    end
  end

  def twicturlate
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

    out = Draw.new
    # out.font = 'DejaVu Sans'
    out.pointsize = 20
    out.font_weight = 600
    out.fill = '#FFFF'
    out.gravity = SouthWestGravity
    out.text_antialias = true
    out.annotate(image, 0, 0, 10, 10, "#{screen_name}")
    
    out.pointsize = 14
    out.fill = '#ffffff'
    out.gravity = SouthEastGravity
    twictures_text = (rand(5) == 0) ? 'donate @ http://twictur.es' : 'http://twictur.es'
    out.annotate(image, 0, 0, 10, 10, twictures_text)

    image.write(Merb.root + '/public/' + image_path)
  end

end