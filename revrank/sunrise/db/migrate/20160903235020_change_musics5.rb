$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics5 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.integer :category, :default => CxbRank::REV_CATEGORY_ORIGINAL
    end
  end

  def self.down
    drop_column :musics, :category
  end
end
