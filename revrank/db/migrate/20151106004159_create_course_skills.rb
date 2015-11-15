$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'

class CreateCourseSkills < ActiveRecord::Migration
  def self.up
    create_table :course_skills do |t|
      t.references :user, :null => false
      t.references :course, :null => false
      t.integer :stat, :default => CxbRank::SP_STATUS_NO_PLAY
      t.float :point
      t.float :rate
      t.boolean :rate_f, :default => true
      t.integer :combo
      t.string :comment
      t.timestamps
    end
    change_table :course_skills do |t|
      t.index ['User'.foreign_key, 'Course'.foreign_key], :unique => true
    end
  end

  def self.down
    drop_table :course_skills
  end
end
