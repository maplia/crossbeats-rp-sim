$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'

class CreateMusics < ActiveRecord::Migration
	music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]

	def self.up
		create_table :musics do |t|
			t.string :text_id, :null => false
			t.integer :number, :null => false, :default => 0
			t.string :title, :null => false
			t.string :subtitle
			t.string :lookup_key, :null => false
			t.string :sort_key, :null => false
			music_diffs.keys.sort.each do |key|
				t.float "#{MUSIC_DIFFS[key].downcase}_level".to_sym
				t.integer "#{MUSIC_DIFFS[key].downcase}_notes".to_sym
			end
			t.boolean :limited, :null => false, :default => false
			t.boolean :hidden, :null => false, :default => false
			t.boolean :display, :null => false, :default => true
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
