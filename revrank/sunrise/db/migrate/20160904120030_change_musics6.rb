$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics6 < ActiveRecord::Migration
  def self.up
    change_column :musics, :added_at_unl, :date, :null => true
  end

  def self.down
    change_column :musics, :added_at_unl, :date, :null => false
  end
end
