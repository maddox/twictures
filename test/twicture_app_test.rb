require File.join(File.dirname(__FILE__), 'test_helper')

class TwictureAppTest < Test::Unit::TestCase
  url, data = register_fake_url(12345678, 'fred')

  setup do
    @app = Twicture::App
  end

  describe "root" do
    it "renders" do
      get '/'
      assert response.ok?
    end
  end

  describe "show action" do
    before do
      get "/i/#{data[:id]}"
    end

    it "renders image tag" do
      assert response.ok?
      assert_match /<img src='\/i\/#{data[:id]}\.gif'/, response.body
    end
  end
end
