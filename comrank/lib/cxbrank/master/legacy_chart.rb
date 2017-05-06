require 'csv'
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

      CSV_COLUMNS = [:text_id, :span_s, :span_e]
      MUSIC_DIFF_PREFIXES.keys.sort.each do |diff|
        CSV_COLUMNS.push("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_level".to_sym)
        CSV_COLUMNS.push("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_notes".to_sym)
      end

      def self.restore_from_csv(csv)
        columns = CSV_COLUMNS.dup
        columns.delete(:text_id)
        columns.delete(:span_s)

        csv.read.each do |row|
          music_id = Music.find_by(:text_id => row.field(:text_id)).id
          span_s = row.field(:span_s)
          data = self.find_by(:music_id => music_id, :span_s => span_s)
          unless data
            data = self.new
            data.music_id = music_id
            data.span_s = span_s
          end
          columns.each do |column|
            data.send("#{column}=".to_sym, row.field(column))
          end
          data.save!
        end
      end

      def self.dump_to_csv(csv, omit_columns=[])
        output_columns = CSV_COLUMNS - omit_columns
        csv << output_columns

        columns = output_columns.dup
        columns.delete(:text_id)
        self.all.joins(:music).each do |chart|
          row = CSV::Row.new(output_columns, [])
          row[:text_id] = chart.music.text_id
          columns.each do |column|
            row[column] = chart.send(column)
          end
          csv << row
        end
      end
    end
  end
end
