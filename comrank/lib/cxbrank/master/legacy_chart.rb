require 'cxbrank/const'
require 'cxbrank/master/base'
require 'cxbrank/master/music'

module CxbRank
  module Master
    class LegacyChart < Base
      belongs_to :music

      def self.last_modified(music_id=nil)
        if music_id.present?
          legacy_charts = self.where(:music_id => music_id)
        else
          legacy_charts = self
        end
        return legacy_charts.maximum(:updated_at)
      end

      def level(diff)
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
      end

      def notes(diff)
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
      end

      def self.get_csv_columns
        columns = [
          {:name => :text_id,   :unique => true, :dump => true, :foreign => Music},
          {:name => :span_s,    :unique => true, :dump => true},
          {:name => :span_e,                     :dump => true},
        ]
        MUSIC_DIFF_PREFIXES.keys.each do |diff|
          columns << {:name => "#{MUSIC_DIFF_PREFIXES[diff]}_level".to_sym, :dump => true}
          columns << {:name => "#{MUSIC_DIFF_PREFIXES[diff]}_notes".to_sym, :dump => true}
        end
        return columns
      end
    end
  end
end
