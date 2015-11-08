$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'

class CreateSkills < ActiveRecord::Migration
  def self.up
		music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]
		create_table :skills do |t|
			t.references :user, :null => false
			t.references :music, :null => false
			music_diffs.keys.sort.each do |key|
				t.integer "#{music_diffs[key].downcase}_stat".to_sym
				t.boolean "#{music_diffs[key].downcase}_locked".to_sym
				t.integer "#{music_diffs[key].downcase}_gauge".to_sym
				t.float "#{music_diffs[key].downcase}_point".to_sym
				t.float "#{music_diffs[key].downcase}_rate".to_sym
				t.boolean "#{music_diffs[key].downcase}_rate_f".to_sym
				t.integer "#{music_diffs[key].downcase}_rank".to_sym
				t.integer "#{music_diffs[key].downcase}_combo".to_sym
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
