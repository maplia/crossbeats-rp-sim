$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'

class CreateMusics < ActiveRecord::Migration
  def self.up
    music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]
    create_table :musics do |t|
      t.string :text_id, :null => false
      t.integer :number, :default => 0
      t.string :title, :null => false
      t.string :subtitle
      t.string :lookup_key, :null => false
      t.string :sort_key, :null => false
      music_diffs.keys.sort.each do |key|
        t.decimal "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_level".to_sym, :precision => 3, :scale => 1
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_notes".to_sym
      end
      t.boolean :limited, :default => false
      t.boolean :hidden, :default => false
      t.boolean :display, :default => true
      t.date :added_at, :default => '2015-07-23'
      t.string :event
      t.timestamps
    end
    change_table :musics do |t|
      t.index :text_id, :unique => true
      t.index :lookup_key, :unique => true
    end
  end

  def self.down
    drop_table :musics
  end
end
