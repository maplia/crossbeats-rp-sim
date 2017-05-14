require 'cxbrank/const'
require 'cxbrank/master/playable'
require 'cxbrank/master/event_music'

module CxbRank
  module Master
    class Event < Playable
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

      def self.get_csv_columns
        return [
          {:name => :text_id, :unique => true, :dump => true},
          {:name => :section,                  :dump => true},
          {:name => :title,                    :dump => true},
          {:name => :span_s,                   :dump => true},
          {:name => :span_e,                   :dump => true},
        ]
      end
    end
  end
end
