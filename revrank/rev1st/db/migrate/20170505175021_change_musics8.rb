$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusics8 < ActiveRecord::Migration
  def self.up
    change_table :musics do |t|
      t.string :jacket
      t.integer :appear, :default => 0
      t.integer :category, :default => 0
      t.integer :hidden_type, :default => CxbRank::SECRET_TYPE_DEFAULT
      t.date :added_at_unl
    end
  end

  def self.down
    remove_column :musics, :jacket
    remove_column :musics, :appear
    remove_column :musics, :category
    remove_column :musics, :hidden_type
    remove_column :musics, :added_at_unl
  end
end
