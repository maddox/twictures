class TwictureMigration < ActiveRecord::Migration
  def self.up
    create_table :twictures do |t|
      t.string   :twitter_url, :null => false
      t.integer  :status
      t.string   :screen_name
      t.string   :text
      t.string   :image_path
      
      t.timestamps
    end 
  end

  def self.down
    drop_table :twictures
  end
end
