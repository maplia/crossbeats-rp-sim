class CreateCourseSkills < ActiveRecord::Migration
  def self.up
    create_table :course_skills do |t|
      t.references :user, :null => false
      t.references :course, :null => false
      t.integer :stat
      t.decimal :point, :precision => 5, :scale => 2
      t.decimal :rate, :precision => 5, :scale => 2
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
