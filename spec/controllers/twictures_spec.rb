require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe Twictures, "index action" do
  before(:each) do
    dispatch_to(Twictures, :index)
  end
end