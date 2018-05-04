$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeMusicSkills < ActiveRecord::Migration[4.2]
  def self.up
    music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]
    change_table :skills do |t|
      music_diffs.keys.sort.each do |key|
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_flawless".to_sym
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_super".to_sym
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_cool".to_sym
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_maxcombo".to_sym
      end
    end
  end

  def self.down
    music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]
    music_diffs.keys.sort.each do |key|
      remove_column :skills, "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_flawless".to_sym
      remove_column :skills, "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_super".to_sym
      remove_column :skills, "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_cool".to_sym
      remove_column :skills, "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_maxcombo".to_sym
    end
  end
end
