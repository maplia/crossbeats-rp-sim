require 'rubygems'
require 'active_record'
require 'cxbrank/music'

module CxbRank
  class Event < ActiveRecord::Base
    has_many :event_musics

    def self.last_modified(text_id=nil, section=nil)
      if text_id.present? and section.present?
        event = self.where(:text_id => text_id, :section => section).first
        return [
          self.where(:text_id => text_id, :section => section).first.updated_at,
          EventMusic.last_modified(event.id)
        ].compact.max
      else
        return [self.maximum(:updated_at), EventMusic.last_modified].compact.max
      end
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
  end

  class EventMusic < ActiveRecord::Base
    include Comparable
    belongs_to :music

    def self.last_modified(event_id=nil, section=nil)
      if event_id.present? and section.present?
        return self.where(:event_id => event_id).maximum(:updated_at)
      else
        return self.maximum(:updated_at)
      end
    end

    def to_hash
      return {
        :mid => music.text_id, :title => music.title, :notes => music.max_notes,
      }
    end

    def <=>(other)
      return seq <=> other.seq
    end
  end
end
