require 'rubygems'
require 'active_record'
require 'chronic'
require 'cxbrank/const'
require 'cxbrank/course'

module CxbRank
  class Music < ActiveRecord::Base
    include Comparable
    has_many :monthlies
    has_many :legacy_charts

    @@mode = nil
    @@date = nil
    @@time = nil

    def self.mode=(mode)
      @@mode = mode
    end

    def self.date=(date)
      if date.present?
        @@date = date
        @@time = Chronic.parse("#{date.strftime('%Y-%m-%d 27:59:59')}")
      end
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

    def self.find_actives
      if @@date.present?
        conditions = ['display = ? and added_at <= ?', true, @@date]
      else
        conditions = {:display => true}
      end
      return self.find(:all, :conditions => conditions)
    end

    def full_title
      return subtitle ? "#{title} #{subtitle}" : title
    end

    def level(diff)
      if @@date.present? and legacy_charts.present?
        legacy_charts.each do |legacy_chart|
          if (legacy_chart.span_s..(legacy_chart.span_e-1)).include?(@@date)
            return legacy_chart.level(diff)
          end
        end
      end
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
    end

    def legacy_level(diff)
      if legacy_charts.blank?
        return nil
      else
        return legacy_charts[0].level(diff)
      end
    end

    def notes(diff)
      if @@date.present? and legacy_charts.present?
        legacy_charts.each do |legacy_chart|
          if (legacy_chart.span_s..(legacy_chart.span_e-1)).include?(@@date)
            return legacy_chart.notes(diff)
          end
        end
      end
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
    end

    def legacy_notes(diff)
      if legacy_charts.blank?
        return nil
      else
        return legacy_charts[0].notes(diff)
      end
    end

    def max_notes
      note_data = []
      music_diffs.keys.each do |diff|
        note_data << (notes(diff) || 0)
      end
      return note_data.max
    end

    def exist?(diff)
      return level(diff).present?
    end

    def exist_legacy?(diff)
      return legacy_level(diff).present?
    end

    def monthly?
      monthlies.each do |monthly|
        if (monthly.span_s..monthly.span_e).include?(@@time || Time.now)
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

    def legacy_level_to_s(diff)
      unless exist_legacy?(diff)
        return '-'
      else
        return (legacy_level(diff) == 0) ? '-' : sprintf(level_format, legacy_level(diff))
      end
    end

    def notes_to_s(diff)
      unless exist?(diff)
        return '-'
      else
        return (notes(diff) == 0) ? '???' : sprintf('%d', notes(diff))
      end
    end

    def legacy_notes_to_s(diff)
      unless exist_legacy?(diff)
        return '-'
      else
        return (legacy_notes(diff) == 0) ? '???' : sprintf('%d', legacy_notes(diff))
      end
    end

    def to_hash
      hash = {
        :text_id => text_id, :number => number,
        :title => title, :subtitle => subtitle, :full_title => full_title,
        :monthly => monthly?, :limited => limited,
      }
      MUSIC_DIFF_PREFIXES.keys.each do |diff|
        if exist?(diff)
          hash[MUSIC_DIFF_PREFIXES[diff]] = {
            :level => level(diff), :notes => notes(diff),
            :has_legacy => exist_legacy?(diff),
          }
        else
          hash[MUSIC_DIFF_PREFIXES[diff]] = {
            :level => nil, :notes => nil,
          }
        end
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

  class LegacyChart < ActiveRecord::Base
    def level(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
    end

    def notes(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
    end
  end

  class MusicSet < Hash
    attr_accessor :last_modified

    def self.load(mode)
      music_set = self.new
      musics = Music.find_actives.sort
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
        courses = Course.find_actives.sort
        music_set[MUSIC_TYPE_REV_COURSE] = courses
      end
      music_set.last_modified = [Music.last_modified, Course.last_modified].compact.max
      return music_set
    end
  end
end
