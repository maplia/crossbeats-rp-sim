$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics8 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.integer :hidden_type, :default => CxbRank::SECRET_TYPE_DEFAULT
    end
  end

  def self.down
    remove_column :musics, :hidden_type
  end
end
