$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeIndex2 < ActiveRecord::Migration
  def self.up
    add_index :musics, [:updated_at]
    add_index :musics, [:added_at]
    add_index :musics, [:added_at_unl]
    add_index :courses, [:updated_at]
    add_index :monthlies, [:updated_at]
    add_index :legacy_charts, [:updated_at]
    add_index :skills, [:user_id, :updated_at]
    add_index :course_skills, [:user_id, :updated_at]
    add_index :events, [:updated_at]
    add_index :events, [:span_s]
    add_index :events, [:span_e]
  end

  def self.down
    remove_index :musics, [:updated_at]
    remove_index :musics, [:added_at]
    remove_index :musics, [:added_at_unl]
    remove_index :courses, [:updated_at]
    remove_index :monthlies, [:updated_at]
    remove_index :legacy_charts, [:updated_at]
    remove_index :skills, [:user_id, :updated_at]
    remove_index :course_skills, [:user_id, :updated_at]
    remove_index :events, [:updated_at]
    remove_index :events, [:span_s]
    remove_index :events, [:span_e]
  end
end
