$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics4 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.integer :appear, :default => CxbRank::REV_VERSION_SUNRISE
      t.date :added_at_unl, :null => false
    end
  end

  def self.down
    drop_column :musics, :appear
    drop_column :musics, :added_at_unl
  end
end
