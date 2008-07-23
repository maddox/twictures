require 'RMagick'
require 'Open-URI'
require 'Json'

include Magick


status = 865566569
url = "http://twitter.com/statuses/show/#{status}.json"
# grab tweet
tweet_json = open(url).read
tweet = JSON.parse(tweet_json)
# tweet = {"user" => {"screen_name" => 'shayarnett'}}
text = tweet["text"]
byline = "#{tweet["user"]["screen_name"]} via twitter"

imagelist = Magick::ImageList.new
imagelist.new_image(1, 10) { self.background_color = '#00eeff' }
imagelist.read("caption:#{tweet["text"]}") do
  self.size = "400x"
  self.pointsize = 24
  self.font = "Lucida Grande"
  self.antialias = true
end
imagelist[1].border!(10,10,'#ffffff')
imagelist[1].border!(10,0,'#00eeff')
imagelist.new_image(1, 40) { self.background_color = '#00eeff' }
image = imagelist.append(true)

out = Draw.new
out.font = 'Lucida Grande'
out.pointsize = 18
out.font_weight = 600
out.fill = '#000000'
out.gravity = SouthEastGravity
out.text_antialias = true
out.annotate(image, 0, 0, 10, 10, byline)

image.write('twicture.png')