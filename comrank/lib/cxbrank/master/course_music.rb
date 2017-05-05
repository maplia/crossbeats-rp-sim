require 'csv'
require 'forwardable'
require 'cxbrank/const'
require 'cxbrank/master/base'
require 'cxbrank/master/music'
require 'cxbrank/master/course'

module CxbRank
  module Master
    class CourseMusic < Base
      extend Forwardable
      belongs_to :course
      belongs_to :music

      def_delegators :music, :title, :subtitle

      def self.create_by_request(body, seq)
        music = Music.where(:jacket => body[:jacket]).first
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
        return music.level(diff)
      end

      def level_to_s
        return music.level_to_s(diff)
      end

      def notes
        return music.notes(diff)
      end

      def notes_to_s
        return music.notes_to_s(diff)
      end

      def <=>(other)
        return seq <=> other.seq
      end

      CSV_COLUMNS = [:text_id, :seq, :music_text_id, :diff]

      def self.restore_from_csv(csv)
        csv.read.each do |row|
          course_id = Course.where(:text_id => row.field(:text_id)).first.id
          data = self.where(:course_id => course_id, :seq => row.field(:seq)).first
          unless data
            data = self.new
            data.course_id = course_id
            data.seq = row.field(:seq)
          end
          data.music_id = Music.where(:text_id => row.field(:music_text_id)).first.id
          data.diff = row.field(:diff)
          data.save!
        end
      end

      def self.dump_to_csv(csv, omit_columns=[])
        output_columns = CSV_COLUMNS - omit_columns
        csv << output_columns

        self.all.joins(:course).joins(:music).each do |course_music|
          row = CSV::Row.new(output_columns, [])
          row[:text_id] = course_music.course.text_id
          row[:seq] = course_music.seq
          row[:music_text_id] = course_music.music.text_id
          row[:diff] = course_music.diff
          csv << row
        end
      end
    end
  end
end
