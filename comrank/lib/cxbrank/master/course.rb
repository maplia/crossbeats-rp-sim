require 'csv'
require 'cxbrank/const'
require 'cxbrank/master/base'
require 'cxbrank/master/format'
require 'cxbrank/master/course_music'

module CxbRank
  module Master
    class Course < Base
      include Comparable
      include Master::Format
      has_many :course_musics

      def self.last_modified
        return [
          self.maximum(:updated_at), CourseMusic.last_modified
        ].compact.max
      end

      def self.find_by_param_id(param_id)
        return self.where(:text_id => param_id).first
      end

      def self.find_by_lookup_key(lookup_key)
        return self.where(:lookup_key => lookup_key).first
      end

      def self.find_actives
        return super(:sort_key)
      end

      def self.create_by_request(body)
        course = self.where(:lookup_key => body[:lookup_key]).first
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

      CSV_COLUMNS = [:lookup_key, :text_id, :title, :sort_key, :level, :limited, :hidden, :deleted, :display, :added_at, :deleted_at]

      def self.restore_from_csv(csv)
        columns = CSV_COLUMNS.dup
        columns.delete(:lookup_key)

        csv.read.each do |row|
          data = self.where(:lookup_key => row.field(:lookup_key)).first
          unless data
            data = self.new
            data.lookup_key = row.field(:lookup_key)
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

        self.all.each do |course|
          row = CSV::Row.new(output_columns, [])
          output_columns.each do |column|
            row[column] = course.send(column)
          end
          csv << row
        end
      end
    end
  end
end
