class Twicture < ActiveRecord::Base
  include Magick
  
  before_create :get_status
  before_create :get_twitter_data
  after_create :twicturlate
  
  validates_presence_of :twitter_url
  validates_format_of :twitter_url, :with => /^http:\/\/(?:www\.)?twitter.com\/\S+\/statuses\/(\d+)/,
                                    :on => :create, :message => "must be a twitter url"
  
  def to_param
    status
  end

  def get_status
    if twitter_url.match(/^http:\/\/(?:www\.)?twitter.com\/\S+\/statuses\/(\d+)/)
      write_attribute(:status, $1)
      return true
    end
    self.errors.add("Url", "must be a twitter url")
    return false
  end
  
  def get_twitter_data
    url = "http://twitter.com/statuses/show/#{status}.json"
    begin
      #grab tweet and catch 403 forbidden errors
      tweet_json = open(url).read
    rescue
      return false
    else
      if tweet_json =~ /Twitter is down for maintenance/
        self.errors.add("Twitter", "is down")
        return false
      end
      tweet = JSON.parse(tweet_json)
      # tweet = {"user" => {"screen_name" => 'shayarnett'}}
      if tweet["user"] && tweet["text"]
        write_attribute(:text, tweet["text"])
        write_attribute(:status, tweet["id"])
        write_attribute(:image_path, 'twictures/' + "#{status}.gif")
        write_attribute(:screen_name, tweet["user"]["screen_name"])  
        return true
      else
        return false
      end
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
    out.annotate(image, 0, 0, 10, 10, "#{screen_name} via twitter")
    
    out.pointsize = 14
    out.fill = '#ffffff'
    out.gravity = SouthEastGravity
    out.annotate(image, 0, 0, 10, 10, 'http://twictur.es')
    
    image.write(Merb.root + '/public/images/' + image_path)
  end

end