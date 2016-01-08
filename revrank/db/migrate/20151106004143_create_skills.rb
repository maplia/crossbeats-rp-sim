$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'

class CreateSkills < ActiveRecord::Migration
  def self.up
    music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]
    create_table :skills do |t|
      t.references :user, :null => false
      t.references :music, :null => false
      music_diffs.keys.sort.each do |key|
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_stat".to_sym, :default => CxbRank::SP_STATUS_NO_PLAY
        t.boolean "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_locked".to_sym
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_gauge".to_sym
        t.decimal "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_point".to_sym, :precision => 5, :scale => 2
        t.decimal "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_rate".to_sym, :precision => 5, :scale => 2
        t.boolean "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_rate_f".to_sym
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_rank".to_sym
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_combo".to_sym
        t.boolean "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_legacy".to_sym, :default => false
      end
      t.string :comment
      t.integer :best_diff
      t.float :best_point, :default => 0.0
      t.integer :iglock_best_diff
      t.float :iglock_best_point, :default => 0.0
      t.timestamps
    end
    change_table :skills do |t|
      t.index ['User'.foreign_key, 'Music'.foreign_key], :unique => true
    end
  end

  def self.down
    drop_table :skills
  end
end
