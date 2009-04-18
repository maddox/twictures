require File.join(File.dirname(__FILE__), 'test_helper')

class TwictureTest < Test::Unit::TestCase
  url  = "http://twitter.com/statuses/show/1.json"
  data = {:user => {:name => 'bob'}, :text => 'foo', :id => 1}
  FakeWeb.register_uri(:get, url, :string => data.to_json)

  describe "new object" do
    before :all do
      @status = Twicture::Status.new :status => 1
    end

    it "generates twitter json url" do
      @status.twitter_json_url.should == url
    end

    it "fetches twitter data" do
      @status.twitter_data.should == {'user' => {'name' => 'bob'}, 'text' => 'foo', 'id' => 1}
    end

    describe "being validated" do
      before :all do
        @status.valid?
      end

      it "generates twitter url" do
        @status.twitter_url.should == "http://twitter.com/bob/statuses/1"
      end

      it "sets #screen_name" do
        @status.screen_name.should == data[:user][:name]
      end

      it "sets #text" do
        @status.text.should == data[:text]
      end
    end
  end
end
