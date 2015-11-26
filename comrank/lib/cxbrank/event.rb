require 'rubygems'
require 'active_record'
require 'cxbrank/music'

module CxbRank
  class Event < ActiveRecord::Base
    has_many :event_musics

    def self.last_modified
      event = self.find(:first, :order => 'updated_at desc')
      return (event ? event.updated_at : nil)
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
