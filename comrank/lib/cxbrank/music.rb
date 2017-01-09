require 'rubygems'
require 'active_record'
require 'chronic'
require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/course'

module CxbRank
  class Music < ActiveRecord::Base
    include Comparable
    has_many :monthlies
    has_many :legacy_charts

    def self.create_by_request(body)
      music = self.where(:lookup_key => body[:lookup_key]).first
      unless music
        music = self.new
        music.number = 0
        music.text_id = body[:text_id]
        music.title = body[:title]
        music.sort_key = body[:sort_key]
        music.lookup_key = body[:lookup_key]
        music.limited = false
        music.unlock_unl = UNLOCK_UNL_TYPE_FC
        music.appear = REV_VERSION_SUNRISE
        music.category = REV_CATEGORY_ORIGINAL
        music.added_at = Date.today
      end
      music.jacket = body[:jacket]
      MUSIC_DIFF_PREFIXES.values.each do |prefix|
        next unless body[prefix.to_sym]
        music.send("#{prefix}_level=", body[prefix.to_sym][:level])
        music.send("#{prefix}_notes=", body[prefix.to_sym][:notes])
      end
      if music.unl_level_changed?
        music.added_at_unl = Date.today
      end
      return music
    end

    def self.last_modified(text_id=nil)
      if text_id.present? and (music = self.find_by_param_id(text_id))
        return [
          music.updated_at,
          Monthly.last_modified(music.id), LegacyChart.last_modified(music.id)
        ].compact.max
      else
        return [
          self.maximum(:updated_at),
          Monthly.last_modified, LegacyChart.last_modified
        ].compact.max
      end
    end

    def self.find_by_param_id(text_id)
      return self.where(:text_id => text_id).first
    end

    def self.find_actives(date=nil)
      actives = self.where(:display => true)
      if SiteSettings.cxb_mode?
        actives = actives.where(:limited => false)
      end
      if date.present?
        actives = actives.where('added_at <= ?', date)
        actives.each do |music| music.date = date end
      end
      if SiteSettings.cxb_mode? or SiteSettings.rev_rev1st_mode?
        actives = actives.order(:number, :sort_key)
      else
        actives = actives.order(:appear, :sort_key)
      end
      return actives
    end

    def date=(date)
      @pivot_date = date
      @pivot_time = Chronic.parse("#{date.strftime('%Y-%m-%d 27:59:59')}")
    end

    def full_title
      return subtitle ? "#{title} #{subtitle}" : title
    end

    def level(diff)
      if @pivot_date.present? and legacy_charts.present?
        legacy_charts.each do |legacy_chart|
          if (legacy_chart.span_s..(legacy_chart.span_e-1)).include?(@pivot_date)
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
      if @pivot_date.present? and legacy_charts.present?
        legacy_charts.each do |legacy_chart|
          if (legacy_chart.span_s..(legacy_chart.span_e-1)).include?(@pivot_date)
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
      SiteSettings.music_diffs.keys.each do |diff|
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
        if (monthly.span_s..monthly.span_e).include?(@pivot_time || Time.now)
          return true
        end
      end
      return false
    end

    def level_to_s(diff)
      unless exist?(diff)
        return '-'
      else
        return (level(diff) == 0) ? '-' : sprintf(SiteSettings.level_format, level(diff))
      end
    end

    def legacy_level_to_s(diff)
      unless exist_legacy?(diff)
        return '-'
      else
        return (legacy_level(diff) == 0) ? '-' : sprintf(SiteSettings.level_format, legacy_level(diff))
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
        :monthly => monthly?, :limited => limited, :deleted => deleted
      }
      MUSIC_DIFF_PREFIXES.keys.each do |diff|
        if exist?(diff) and !(diff == MUSIC_DIFF_UNL and unlock_unl == UNLOCK_UNL_TYPE_NEVER)
          hash[MUSIC_DIFF_PREFIXES[diff]] = {
            :level => level_to_s(diff), :notes => notes(diff),
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
    def self.last_modified(music_id=nil)
      if music_id.present?
        monthlies = self.where(:music_id => music_id)
      else
        monthlies = self
      end
      return monthlies.maximum(:updated_at)
    end
  end

  class LegacyChart < ActiveRecord::Base
    def self.last_modified(music_id=nil)
      if music_id.present?
        legacy_charts = self.where(:music_id => music_id)
      else
        legacy_charts = self
      end
      return legacy_charts.maximum(:updated_at)
    end

    def level(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
    end

    def notes(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
    end
  end

  class MusicSet
    attr_reader :last_modified

    def initialize(date=nil)
      @date = date
      if SiteSettings.cxb_mode?
        @hash = {
          MUSIC_TYPE_NORMAL => [], MUSIC_TYPE_SPECIAL => [],
          MUSIC_TYPE_DELETED => [],
        }
      elsif SiteSettings.rev_rev1st_mode?
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
      @last_modified = [Music.last_modified, Course.last_modified].compact.max
    end

    def load!
      musics = Music.find_actives(@date)
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
            if SiteSettings.rev_rev1st_mode?
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
