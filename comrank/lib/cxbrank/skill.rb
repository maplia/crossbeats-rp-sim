require 'active_record'
require 'bigdecimal'
require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/user'
require 'cxbrank/master/music_set'
require 'cxbrank/master/music'
require 'cxbrank/master/course'
require 'cxbrank/playdata/music_skill'
require 'cxbrank/playdata/course_skill'
require 'cxbrank/playdata/chart'

module CxbRank
  class Skill < PlayData::MusicSkill
  end

  class CourseSkill < PlayData::CourseSkill
  end

  class SkillSet
    attr_accessor :last_modified, :total_point

    def initialize(user, skill_options={})
      @user = user
      @skill_options = skill_options
      if SiteSettings.cxb_mode?
        @hash = {
          MUSIC_TYPE_NORMAL => {:skills => [], :point => 0.0},
          MUSIC_TYPE_SPECIAL => {:skills => [], :point => 0.0},
          MUSIC_TYPE_DELETED => {:skills => [], :point => 0.0},
        }
      else
        @hash = {
          MUSIC_TYPE_REV_SINGLE => {:skills => [], :point => 0.0},
          MUSIC_TYPE_REV_COURSE => {:skills => [], :point => 0.0},
          MUSIC_TYPE_REV_LIMITED => {:skills => [], :point => 0.0},
          MUSIC_TYPE_REV_BONUS => {:skills => [], :point => 0.0},
          MUSIC_TYPE_REV_COURSE_LIMITED => {:skills => [], :point => 0.0},
        }
      end
      if @user
        @music_set = nil
        @last_modified = [
          PlayData::MusicSkill.last_modified(@user), PlayData::CourseSkill.last_modified(@user)
        ].compact.max
      else
        @music_set = Master::MusicSet.new
        @last_modified = @music_set.last_modified
      end
    end

    def load!
      PlayData::MusicSkill.ignore_locked = @skill_options[:ignore_locked]

      music_skills = PlayData::MusicSkill.find_by_user(@user, @skill_options).sort
      if SiteSettings.cxb_mode?
        @hash[MUSIC_TYPE_NORMAL] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_SPECIAL] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_DELETED] = {:skills => [], :point => 0.0}
        music_skills.each do |skill|
          if skill.music.deleted?
            @hash[MUSIC_TYPE_DELETED][:skills] << skill
          elsif skill.music.monthly?
            @hash[MUSIC_TYPE_SPECIAL][:skills] << skill
          else
            @hash[MUSIC_TYPE_NORMAL][:skills] << skill
          end
        end
      else
        course_skills = PlayData::CourseSkill.find_by_user(@user, @skill_options).sort
        @hash[MUSIC_TYPE_REV_SINGLE] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_LIMITED] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_DELETED] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_BONUS] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_COURSE] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_COURSE_LIMITED] = {:skills => [], :point => 0.0}
        music_skills.dup.each do |skill|
          if skill.deleted_music?
            @hash[MUSIC_TYPE_REV_DELETED][:skills] << skill
          elsif skill.music.limited
            @hash[MUSIC_TYPE_REV_LIMITED][:skills] << skill
          else
            @hash[MUSIC_TYPE_REV_SINGLE][:skills] << skill
          end
        end
        course_skills.dup.each do |skill|
          if skill.course.limited
            @hash[MUSIC_TYPE_REV_COURSE_LIMITED][:skills] << skill
          else
            @hash[MUSIC_TYPE_REV_COURSE][:skills] << skill
          end
        end
      end
      calc!
    end

    def calc!
      @total_point = 0.0
      @hash.each do |type, type_set|
        target_count = (MUSIC_TYPE_ST_COUNTS[type] || type_set[:skills].size)
        type_set[:skills][0...target_count].each do |skill|
          next if (skill.target_point || 0.0) == 0.0
          type_set[:point] += skill.target_point
          skill.rp_target = true
        end
        @total_point += type_set[:point]
      end
      if SiteSettings.rev_mode?
        if !SiteSettings.rev_sunrise_mode?
          min_target = @hash[MUSIC_TYPE_REV_SINGLE][:skills][MUSIC_TYPE_ST_COUNTS[MUSIC_TYPE_REV_SINGLE]-1]
        end
        @hash[MUSIC_TYPE_REV_SINGLE][:skills].each do |skill|
          if !SiteSettings.rev_sunrise_mode?
            if !skill.rp_target? and skill.cleared?(MUSIC_DIFF_UNL) and (min_target.target_point > skill.target_point)
              @hash[MUSIC_TYPE_REV_BONUS][:skills] << skill
            end
          else
            if skill.cleared?(MUSIC_DIFF_UNL)
              @hash[MUSIC_TYPE_REV_BONUS][:skills] << skill
            end
          end
        end
        @hash[MUSIC_TYPE_REV_BONUS][:skills].sort! do |a, b|
          ((a.locked(MUSIC_DIFF_UNL) ? 1 : 0) <=> (b.locked(MUSIC_DIFF_UNL) ? 1 : 0)).nonzero? ||
            (-a.unlimited_bonus <=> -b.unlimited_bonus)
        end
        if @user and @user.point_direct
          @hash[MUSIC_TYPE_REV_BONUS][:point] =
            @user.point - @hash[MUSIC_TYPE_REV_SINGLE][:point] - @hash[MUSIC_TYPE_REV_COURSE][:point]
        else
          @hash[MUSIC_TYPE_REV_BONUS][:skills].each do |skill|
            if PlayData::MusicSkill.ignore_locked or !skill.locked(MUSIC_DIFF_UNL)
              if !SiteSettings.rev_sunrise_mode?
                @hash[MUSIC_TYPE_REV_BONUS][:point] += skill.point(MUSIC_DIFF_UNL) * BONUS_RATE_UNLIMITED
              else
                @hash[MUSIC_TYPE_REV_BONUS][:point] += skill.unlimited_bonus
              end
            end
          end
          @hash[MUSIC_TYPE_REV_BONUS][:point] = BigDecimal.new(@hash[MUSIC_TYPE_REV_BONUS][:point].to_s).floor(2)
        end
        @total_point += @hash[MUSIC_TYPE_REV_BONUS][:point]
      end
    end

    def [](key)
      return @hash[key]
    end
  end

  class SkillMaxSet < SkillSet
    def initialize
      super(nil)
    end

    def load!
      @music_set.load!
      if SiteSettings.cxb_mode?
        [MUSIC_TYPE_NORMAL, MUSIC_TYPE_SPECIAL].each do |type|
          @music_set[type].each do |music|
            @hash[type][:skills] << PlayData::MusicSkill.max(music)
          end
        end
      else
        if !SiteSettings.rev_rev1st_mode?
          @music_set[MUSIC_TYPE_REV_SINGLE].each_value do |musics|
            musics.each do |music|
              @hash[MUSIC_TYPE_REV_SINGLE][:skills] << PlayData::MusicSkill.max(music)
            end
          end
        else
          @music_set[MUSIC_TYPE_REV_SINGLE].each do |music|
            @hash[MUSIC_TYPE_REV_SINGLE][:skills] << PlayData::MusicSkill.max(music)
          end
        end
        @music_set[MUSIC_TYPE_REV_COURSE].each do |course|
          @hash[MUSIC_TYPE_REV_COURSE][:skills] << PlayData::CourseSkill.max(course)
        end
      end
      @hash.each do |type, type_set|
        type_set[:skills].sort!
      end
      calc!
      @hash.each do |type, type_set|
        next if type == MUSIC_TYPE_REV_BONUS
        target_count = (MUSIC_TYPE_ST_COUNTS[type] || type_set[:skills].size)
        type_set[:skills].delete_if do |skill|
          !skill.rp_target? and type_set[:skills][target_count-1].best_point != skill.best_point
        end
      end
    end
  end

  class SkillChart < PlayData::Chart
  end
end
