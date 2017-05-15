require 'forwardable'
require 'cxbrank/const'
require 'cxbrank/master/base'
require 'cxbrank/master/music'
require 'cxbrank/master/course'

module CxbRank
  module Master
    class CourseMusic < Base
      extend Forwardable
      belongs_to :music
      belongs_to :course

      def_delegators :music, :title, :subtitle

      def self.create_by_request(body, seq)
        music = Music.find_by(:jacket => body[:jacket])
        unless music
          return nil
        end
        course_music = self.new
        course_music.music = music
        course_music.seq = seq
        course_music.diff = MUSIC_DIFF_PREFIXES.invert[body[:diff]]
        return course_music
      end

      def level
        return music.level(diff, true)
      end

      def level_to_s
        return music.level_to_s(diff, true)
      end

      def notes
        return music.notes(diff, true)
      end

      def notes_to_s
        return music.notes_to_s(diff, true)
      end

      def <=>(other)
        return seq <=> other.seq
      end

      def self.get_csv_columns
        return [
          {:name => :text_id,       :unique => true, :dump => true, :foreign => Course},
          {:name => :seq,           :unique => true, :dump => true},
          {:name => :music_text_id,                  :dump => true, :foreign => Music},
          {:name => :diff,                           :dump => true},
        ]
      end
    end
  end
end
