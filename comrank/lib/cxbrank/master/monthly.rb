require 'csv'
require 'active_record'
require 'cxbrank/master/base'
require 'cxbrank/master/music'

module CxbRank
  module Master
    class Monthly < Base
      belongs_to :music

      def self.last_modified
        return self.maximum(:updated_at)
      end

      CSV_COLUMNS = [:text_id, :span_s, :span_e]

      def self.restore_from_csv(csv)
        columns = CSV_COLUMNS.dup
        columns.delete(:text_id)
        columns.delete(:span_s)

        csv.read.each do |row|
          music_id = Music.where(:text_id => row.field(:text_id)).first.id
          data = self.where(:music_id => music_id, :span_s => row.field(:span_s)).first
          unless data
            data = self.new
            data.music_id = music_id
            data.span_s = row.field(:span_s)
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
        self.all.joins(:music).each do |data|
          row = CSV::Row.new(output_columns, [])
          row[:text_id] = data.music.text_id
          columns.each do |column|
            row[column] = data.send(column)
          end
          csv << row
        end
      end
    end
  end
end
