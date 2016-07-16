$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics3 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.string :jacket
    end
  end

  def self.down
    drop_column :musics, :jacket
  end
end
