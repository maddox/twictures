require File.join(File.dirname(__FILE__), 'test_helper')

class TwictureTest < Test::Unit::TestCase
  url, data = register_fake_url(1, 'bob')

  describe "new object" do
    before :all do
      @status = Twicture::Status.new :status => 1
    end

    it "generates twitter json url" do
      @status.twitter_json_url.should == url
    end

    it "fetches twitter data" do
      @status.twitter_data.should == {'user' => {'screen_name' => 'bob'}, 'text' => 'foo', 'id' => 1}
    end

    describe "being validated" do
      before :all do
        @status.valid?
      end

      it "generates twitter url" do
        @status.twitter_url.should == "http://twitter.com/bob/statuses/1"
      end

      it "sets #screen_name" do
        @status.screen_name.should == data[:user][:screen_name]
      end

      it "sets #text" do
        @status.text.should == data[:text]
      end

      it "sets #content_type" do
        @status.content_type.should == 'image/gif'
      end

      it "sets #filename" do
        @status.filename.should == "1.gif"
      end

      it "saves file" do
        expected_file = File.join(AttachmentFu.root_path, 'i', '1.gif')
        assert !File.exist?(expected_file)
        @status.save!
        File.expand_path(@status.full_path).should == File.expand_path(expected_file)
        assert  File.exist?(expected_file)
      end
    end
  end
end
