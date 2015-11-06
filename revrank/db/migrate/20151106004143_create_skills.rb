$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'

class CreateSkills < ActiveRecord::Migration
	MUSIC_DIFFS = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]

  def self.up
		create_table :skills do |t|
			t.references :user, :null => false
			t.references :music, :null => false
			MUSIC_DIFFS.keys.sort.each do |key|
				t.integer "#{MUSIC_DIFFS[key].downcase}.stat".to_sym
				t.boolean "#{MUSIC_DIFFS[key].downcase}_locked".to_sym
				t.integer "#{MUSIC_DIFFS[key].downcase}.gauge".to_sym
				t.float "#{MUSIC_DIFFS[key].downcase}.point".to_sym
				t.float "#{MUSIC_DIFFS[key].downcase}.rate".to_sym
				t.boolean "#{MUSIC_DIFFS[key].downcase}.rate_f".to_sym
				t.integer "#{MUSIC_DIFFS[key].downcase}.rank".to_sym
				t.integer "#{MUSIC_DIFFS[key].downcase}.combo".to_sym
			end
			t.string :comment
			t.integer :best_diff
			t.float :best_point, :default => 0.0
			t.integer :iglock_best_diff
			t.float :iglock_best_point, :default => 0.0
			t.timestamps
		end
		change_table :skills do |t|
			t.index ['User'.foreign_key, 'Music'.foreign_key], :unique => true
		end
  end

  def self.down
		drop_table :skills
  end
end
