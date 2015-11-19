require 'rubygems'
require 'active_record'
require 'cxbrank/const'

module CxbRank
  class Course < ActiveRecord::Base
    include Comparable
    has_many :course_musics

    def self.last_modified
      course = self.find(:first, :order => 'updated_at desc')
      return (course ? course.updated_at : nil)
    end

    def self.find_by_param_id(param_id)
      return self.find(:first, :conditions => {:text_id => param_id})
    end

    def self.create_by_request(body)
      course = self.find(:first, :conditions => {:lookup_key => body[:lookup_key]})
      unless item
        course = self.new
        course.text_id = body[:lookup_key]
        course.name = body[:lookup_key]
        course.level = 0
        course.sort_key = body[:lookup_key]
        course.lookup_key = body[:lookup_key]
      end
      return course
    end

    def name
      return title
    end

    def notes
      sum = 0
      course_musics.each do |course_music|
        sum += course_music.notes
      end
      return sum
    end

    def level_to_s
      return (level == 0) ? '-' : sprintf(LEVEL_FORMATS[MODE_REV], level)
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
