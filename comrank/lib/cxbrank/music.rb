require 'rubygems'
require 'active_record'
require 'cxbrank/const'
require 'cxbrank/course'

module CxbRank
  class Music < ActiveRecord::Base
    include Comparable
    has_many :monthlies

    @@mode = nil
    @@ignore_locked = false

    def self.mode=(mode)
      @@mode = mode
    end

    def music_diffs
      return MUSIC_DIFFS[@@mode]
    end

    def level_format
      return LEVEL_FORMATS[@@mode]
    end

    def self.create_by_request(body)
      music = self.find(:first, :conditions => {:lookup_key => body[:lookup_key]})
      unless music
        music = self.new
        music.number = 0
        music.text_id = body[:text_id]
        music.title = body[:title]
        music.sort_key = body[:sort_key]
        music.lookup_key = body[:lookup_key]
        music.limited = false
        MUSIC_DIFF_PREFIXES.values.each do |prefix|
          next unless body[prefix.to_sym]
          music.send("#{prefix}_level=", body[prefix.to_sym][:level])
          music.send("#{prefix}_notes=", body[prefix.to_sym][:notes])
        end
      end
      return music
    end


    def self.last_modified
      music = self.find(:first, :order => 'updated_at desc')
      return (music ? music.updated_at : nil)
    end

    def self.find_by_param_id(param_id)
      return self.find(:first, :conditions => {:text_id => param_id})
    end

    def full_title
      return subtitle ? "#{title} #{subtitle}" : title
    end

    def level(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
    end

    def notes(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
    end

    def max_notes
      note_data = []
      music_diffs.keys.each do |diff|
        note_data << notes(diff)
      end
      return note_data.max
    end

    def exist?(diff)
      return level(diff).present?
    end

    def monthly?(date=Time.now)
      monthlies.each do |monthly|
        if (monthly.span_s..monthly.span_e).include?(date)
          return true
        end
      end
      return false
    end

    def level_to_s(diff)
      unless exist?(diff)
        return '-'
      else
        return (level(diff) == 0) ? '-' : sprintf(level_format, level(diff))
      end
    end

    def notes_to_s(diff)
      unless exist?(diff)
        return '-'
      else
        return (notes(diff) == 0) ? '???' : sprintf('%d', notes(diff))
      end
    end

    def to_hash
      hash = {
        :text_id => text_id, :number => number,
        :title => title, :subtitle => subtitle, :full_title => full_title,
        :monthly => monthly?, :limited => limited,
      }
      music_diffs.keys.each do |diff|
        hash[MUSIC_DIFF_PREFIXES[diff]] = {
          :level => level(diff), :notes => notes(diff),
        }
      end

      return hash
    end

    def <=>(other)
      if number != other.number
        return number <=> other.number
      else
        return sort_key <=> other.sort_key
      end
    end
  end

  class Monthly < ActiveRecord::Base
  end

  class MusicSet < Hash
    attr_accessor :last_modified

    def self.load(mode)
      music_set = self.new
      musics = Music.find(:all, :conditions => {:display => true}).sort
      if mode == MODE_CXB
        music_set[MUSIC_TYPE_NORMAL] = []
        music_set[MUSIC_TYPE_SPECIAL] = []
        musics.each do |music|
          if music.monthly?
            music_set[MUSIC_TYPE_SPECIAL] << music
          else
            music_set[MUSIC_TYPE_NORMAL] << music
          end
        end
      else
        music_set[MUSIC_TYPE_REV_SINGLE] = musics
        courses = Course.find(:all, :conditions => {:display => true}).sort
        music_set[MUSIC_TYPE_REV_COURSE] = courses
      end
      music_set.last_modified = [Music.last_modified, Course.last_modified].compact.max
      return music_set
    end
  end
end
