require 'rubygems'
require 'active_record'
require 'cxbrank/const'

module CxbRank
  class Course < ActiveRecord::Base
    include Comparable
    has_many :course_musics

    @@date = nil

    def self.date=(date)
      @@date = date
    end

    def self.last_modified
      return [
        self.maximum(:updated_at), CourseMusic.last_modified
      ].compact.max
    end

    def self.find_by_param_id(param_id)
      return self.where(:text_id => param_id).first
    end

    def self.find_actives(date=nil)
      actives = self.where(:display => true)
      if date.present?
        actives = actives.where('added_at <= ?', date)
      end
      return actives
    end

    def self.create_by_request(body)
      course = self.find(:first, :conditions => {:lookup_key => body[:lookup_key]})
      unless course
        course = self.new
        course.text_id = body[:lookup_key]
        course.title = body[:lookup_key]
        course.level = 0
        course.sort_key = body[:lookup_key]
        course.lookup_key = body[:lookup_key]
        course.added_at = Date.today
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
      return (level == 0) ? '&ndash;' : sprintf(LEVEL_FORMATS[MODE_REV], level)
    end

    def notes_to_s
      return (notes == 0) ? '???' : sprintf('%d', notes)
    end

    def <=>(other)
      return sort_key <=> other.sort_key
    end
  end

  class CourseMusic < ActiveRecord::Base
    include Comparable
    belongs_to :music

    def self.last_modified
      return self.maximum(:updated_at)
    end

    def title
      return music.title
    end

    def subtitle
      return music.subtitle
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
  end
end
