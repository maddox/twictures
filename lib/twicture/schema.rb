ActiveRecord::Schema.define do
  create_table :twicture_statuses, :force => true do |t|
    t.integer :status,      :limit => 11
    t.string  :screen_name
    t.string  :text
    t.string  :filename
    t.string  :content_type
    t.integer :size
    t.timestamps
  end

  add_index :twicture_statuses, :status, :unique => true
end
