class CreateLegacyCharts < ActiveRecord::Migration
  def self.up
    music_diffs = CxbRank::MUSIC_DIFFS[CxbRank::MODE_REV]
    create_table :legacy_charts do |t|
      t.references :music, :null => false
      t.date :span_s, :null => false
      t.date :span_e, :null => false
      music_diffs.keys.sort.each do |key|
        t.decimal "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_level".to_sym, :precision => 3, :scale => 1
        t.integer "#{CxbRank::MUSIC_DIFF_PREFIXES[key]}_notes".to_sym
      end
      t.timestamps
    end
    change_table :legacy_charts do |t|
      t.index ['Music'.foreign_key, :span_s], :unique => true
    end
  end

  def self.down
    drop_table :legacy_charts
  end
end
