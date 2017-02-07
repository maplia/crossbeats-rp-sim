require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/monthly'

module CxbRank
  class MusicSet
    attr_reader :last_modified
    
    def self.last_modified
      return [Music.last_modified, Course.last_modified, Monthly.last_modified].compact.max
    end

    def initialize
      if SiteSettings.cxb_mode?
        @hash = {
          MUSIC_TYPE_NORMAL => [], MUSIC_TYPE_SPECIAL => [],
          MUSIC_TYPE_DELETED => [],
        }
      elsif SiteSettings.rev1st_mode?
        @hash = {
          MUSIC_TYPE_REV_SINGLE => [], MUSIC_TYPE_REV_LIMITED => [],
          MUSIC_TYPE_REV_COURSE => [], MUSIC_TYPE_REV_COURSE_LIMITED => [],
        }
      else
        @hash = {
          MUSIC_TYPE_REV_SINGLE => {
            REV_CATEGORY_LICENSE => [], REV_CATEGORY_ORIGINAL => [], REV_CATEGORY_IOSAPP => [],
          },
          MUSIC_TYPE_REV_LIMITED => [], MUSIC_TYPE_REV_DELETED => [],
          MUSIC_TYPE_REV_COURSE => [], MUSIC_TYPE_REV_COURSE_LIMITED => [],
        }
      end
      @last_modified = MusicSet.last_modified
    end

    def load!
      musics = Music.find_actives
      if SiteSettings.cxb_mode?
        musics.each do |music|
          if music.deleted?
            @hash[MUSIC_TYPE_DELETED] << music
          elsif music.monthly?
            @hash[MUSIC_TYPE_SPECIAL] << music
          elsif !music.limited?
            @hash[MUSIC_TYPE_NORMAL] << music
          end
        end
      else
        musics.each do |music|
          if music.deleted?
            @hash[MUSIC_TYPE_REV_DELETED] << music
          elsif music.limited?
            @hash[MUSIC_TYPE_REV_LIMITED] << music
          else
            if SiteSettings.rev1st_mode?
              @hash[MUSIC_TYPE_REV_SINGLE] << music
            else
              @hash[MUSIC_TYPE_REV_SINGLE][music.category] << music
            end
          end
        end
        courses = Course.find_actives(@date)
        courses.each do |course|
          if course.limited?
            @hash[MUSIC_TYPE_REV_COURSE_LIMITED] << course
          else
            @hash[MUSIC_TYPE_REV_COURSE] << course
          end
        end
      end
    end

    def [](key)
      return @hash[key]
    end
  end
end
