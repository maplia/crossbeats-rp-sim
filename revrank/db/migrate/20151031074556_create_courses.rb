class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table :courses do |t|
      t.string :text_id, :null => false
      t.string :name, :null => false
      t.string :lookup_key, :null => false
      t.string :sort_key, :null => false
      t.decimal :level, :precision => 2, :scale => 0
      t.boolean :limited, :default => false
      t.boolean :hidden, :default => false
      t.boolean :display, :default => true
      t.date :added_at, :default => '2015-07-23'
      t.string :event
      t.timestamps
    end
    change_table :courses do |t|
      t.index :text_id, :unique => true
      t.index :lookup_key, :unique => true
    end
  end

  def self.down
    drop_table :courses
  end
end
