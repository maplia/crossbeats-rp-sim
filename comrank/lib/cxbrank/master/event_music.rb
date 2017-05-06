require 'csv'
require 'forwardable'
require 'cxbrank/master/base'
require 'cxbrank/master/music'
require 'cxbrank/master/event'

module CxbRank
  module Master
    class EventMusic < Base
      extend Forwardable
      belongs_to :event
      belongs_to :music

      def_delegators :music, :text_id, :title, :max_notes

      def to_hash
        return {
          :mid => text_id, :title => title, :notes => max_notes,
        }
      end

      def <=>(other)
        return seq <=> other.seq
      end

      CSV_COLUMNS = [:text_id, :seq, :music_text_id]

      def self.restore_from_csv(csv)
        csv.read.each do |row|
          event_id = Event.find_by(:text_id => row.field(:text_id)).id
          seq = row.field(:seq)
          music_id = Music.find_by(:text_id => row.field(:music_text_id)).id
          data = self.find_by(:event_id => event_id, :seq => seq)
          unless data
            data = self.new
            data.event_id = event_id
            data.seq = seq
          end
          data.music_id = music_id
          data.save!
        end
      end

      def self.dump_to_csv(csv, omit_columns=[])
        output_columns = CSV_COLUMNS - omit_columns
        csv << output_columns

        columns = output_columns.dup
        columns.delete(:text_id)
        columns.delete(:music_text_id)
        self.all.joins(:event).joins(:music).each do |event_music|
          row = CSV::Row.new(output_columns, [])
          row[:text_id] = event_music.event.text_id
          row[:music_text_id] = event_music.music.text_id
          columns.each do |column|
            row[column] = event_music.send(column)
          end
          csv << row
        end
      end
    end
  end
end
