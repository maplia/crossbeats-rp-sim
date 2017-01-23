$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics7 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.date :deleted_at
    end
    change_table :courses do |t|
      t.boolean :deleted, :default => false
      t.date :deleted_at
    end
  end

  def self.down
    remove_column :musics, :deleted_at
    remove_column :courses, :deleted
    remove_column :courses, :deleted_at
  end
end
