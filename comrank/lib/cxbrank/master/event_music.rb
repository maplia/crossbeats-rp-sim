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

      def self.get_csv_columns
        return [
          {:name => :text_id,       :unique => true, :dump => true, :foreign => Event},
          {:name => :seq,           :unique => true, :dump => true},
          {:name => :music_text_id,                  :dump => true, :foreign => Music},
        ]
      end
    end
  end
end
