require 'cxbrank/const'
require 'cxbrank/master/playable'
require 'cxbrank/master/course_music'

module CxbRank
  module Master
    class Course < Playable
      has_many :course_musics

      def self.last_modified
        return [
          self.maximum(:updated_at), CourseMusic.last_modified
        ].compact.max
      end

      def self.find_actives
        return super(:sort_key)
      end

      def self.create_by_request(body)
        course = self.find_by(:lookup_key => body[:lookup_key])
        unless course
          course = self.new
          course.text_id = body[:text_id]
          course.title = body[:title]
          course.level = 0
          course.sort_key = body[:text_id]
          course.lookup_key = body[:lookup_key]
          course.added_at = Date.today
          course.limited = true
          body[:musics].each_with_index do |body_music, i|
            course_music = CourseMusic.create_by_request(body_music, i+1)
            if course_music
              course.course_musics << course_music
            end
          end
        end
        return course
      end

      def subtitle
        return nil
      end

      def notes
        sum = 0
        course_musics.each do |course_music|
          sum += course_music.notes
        end
        return sum
      end

      def level_to_s
        return sprintf_for_level(level)
      end

      def notes_to_s
        return sprintf_for_notes(notes)
      end

      def <=>(other)
        return sort_key <=> other.sort_key
      end

      def self.get_csv_columns
        return [
          {:name => :lookup_key, :unique => true, :dump => true},
          {:name => :text_id,                     :dump => true},
          {:name => :title,                       :dump => true},
          {:name => :sort_key,                    :dump => true},
          {:name => :level,                       :dump => true},
          {:name => :limited,                     :dump => true},
          {:name => :hidden,                      :dump => true},
          {:name => :deleted,                     :dump => true},
          {:name => :display,                     :dump => true},
          {:name => :added_at,                    :dump => true},
          {:name => :deleted_at,                  :dump => true},
        ]
      end
    end
  end
end
