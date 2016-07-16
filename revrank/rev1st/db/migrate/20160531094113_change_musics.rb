$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.integer :unlock_unl, :default => 0
    end
  end

  def self.down
    drop_column :musics, :unlock_unl
  end
end
