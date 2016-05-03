class EventMusics < ActiveRecord::Migration
  def self.up
    create_table :event_musics do |t|
      t.references :event, :null => false
      t.integer :seq, :null => false
      t.references :music, :null => false
      t.timestamps
    end
    change_table :event_musics do |t|
      t.index ['Event'.foreign_key, :seq], :unique => true
    end
  end

  def self.down
    drop_table :event_musics
  end
end
