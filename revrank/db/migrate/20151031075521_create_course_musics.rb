class CreateCourseMusics < ActiveRecord::Migration
	def self.up
		create_table :course_musics do |t|
			t.references :course, :null => false
			t.integer :seq, :null => false
			t.references :music, :null => false
			t.integer :diff, :null => false
			t.timestamps
		end
		change_table :course_musics do |t|
			t.index ['Course'.foreign_key, :seq], :unique => true
		end
	end

	def self.down
		drop_table :course_musics
	end
end
