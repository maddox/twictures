require File.join(File.dirname(__FILE__), 'test_helper')

class TwictureAppTest < Test::Unit::TestCase
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
      get "/i/12345678"
    end

    it "renders image tag" do
      assert response.ok?
      assert_match /<img src='\/i\/12345678\.gif'/, response.body
    end
  end
end
