require 'csv'
require 'cxbrank/const'
require 'cxbrank/master/base'
require 'cxbrank/master/event_music'

module CxbRank
  module Master
    class Event < Base
      has_many :event_musics

      def self.last_modified(text_id=nil, section=nil)
        if text_id.present? and section.present?
          event = self.find_by(:text_id => text_id, :section => section)
          return [
            self.find_by(:text_id => text_id, :section => section).updated_at,
            EventMusic.last_modified(event.id)
          ].compact.max
        else
          return [self.maximum(:updated_at), EventMusic.last_modified].compact.max
        end
      end

      def sheet_uri
        return SiteSettings.join_site_base(File.join(EVENT_SHEET_VIEW_URI, text_id))
      end

      def to_hash
        event_music_hashes = []
        event_musics.sort.each do |event_music|
          event_music_hashes << event_music.to_hash
        end

        return {
          :text_id => text_id,
          :event_musics => event_music_hashes,
          :span => {:span_s => span_s.strftime('%Y/%m/%d'), :span_e => span_e.strftime('%Y/%m/%d')},
        }
      end

      def <=>(other)
        return -(span_s <=> other.span_s)
      end

      CSV_COLUMNS = [:text_id, :section, :title, :span_s, :span_e]

      def self.restore_from_csv(csv)
        columns = CSV_COLUMNS.dup
        columns.delete(:text_id)

        csv.read.each do |row|
          data = self.find_by(:text_id => row.field(:text_id))
          unless data
            data = self.new
            data.text_id = row.field(:text_id)
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

        self.all.each do |event|
          row = CSV::Row.new(output_columns, [])
          output_columns.each do |column|
            row[column] = event.send(column)
          end
          csv << row
        end
      end
    end
  end
end
