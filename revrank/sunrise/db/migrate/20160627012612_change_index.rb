$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeIndex < ActiveRecord::Migration
  def self.up
    add_index :skills, [:music_id]
    add_index :skills, [:music_id, :esy_score, :esy_rate]
    add_index :skills, [:music_id, :std_score, :std_rate]
    add_index :skills, [:music_id, :hrd_score, :hrd_rate]
    add_index :skills, [:music_id, :mas_score, :mas_rate]
    add_index :skills, [:music_id, :unl_score, :unl_rate]
  end

  def self.down
    remove_index :skills, [:music_id]
    remove_index :skills, [:music_id, :esy_score, :esy_rate]
    remove_index :skills, [:music_id, :std_score, :std_rate]
    remove_index :skills, [:music_id, :hrd_score, :hrd_rate]
    remove_index :skills, [:music_id, :mas_score, :mas_rate]
    remove_index :skills, [:music_id, :unl_score, :unl_rate]
  end
end
