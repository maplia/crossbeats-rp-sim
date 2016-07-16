$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics2 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.boolean :deleted, :default => false
    end
  end

  def self.down
    drop_column :musics, :deleted
  end
end
