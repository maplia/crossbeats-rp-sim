class Events < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :text_id, :null => false
      t.integer :section, :default => 0
      t.string :title, :null => false
      t.datetime :span_s, :null => false
      t.datetime :span_e, :null => false
      t.timestamps
    end
    change_table :events do |t|
      t.index [:text_id, :section], :unique => true
    end
  end

  def self.down
    drop_table :events
  end
end
