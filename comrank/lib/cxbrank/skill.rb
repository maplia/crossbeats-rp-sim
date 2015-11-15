require 'bigdecimal'
require 'rubygems'
require 'active_record'
require 'cxbrank/const'
require 'cxbrank/user'
require 'cxbrank/music'

module CxbRank
  class Skill < ActiveRecord::Base
    include Comparable
    belongs_to :music

    MUSIC_DIFF_PREFIXES.each do |diff, diff_prefix|
      validates_format_of "#{diff_prefix}_point_before_type_cast".to_sym,
        :allow_nil => true, :allow_blank => true,
        :with => /\A\d+(\.\d+)?\z/, :message => SKILL_ERRORS[diff][ERROR_RP_NOT_NUMERIC]
      validate "validate_#{diff_prefix}_point_range".to_sym
      validates_presence_of "#{diff_prefix}_rate".to_sym,
        :if => (lambda do |a| a.cleared?(diff) and a.point(diff).blank? end),
        :message => SKILL_ERRORS[diff][ERROR_RP_AND_RATE_NOT_EXIST]
      validates_format_of "#{diff_prefix}_rate_before_type_cast",
        :allow_nil => true, :allow_blank => true,
        :with => /\A\d+(\.\d+)?\z/, :message => SKILL_ERRORS[diff][ERROR_RATE_NOT_NUMERIC]
      validates_numericality_of "#{diff_prefix}_rate".to_sym,
        :allow_nil => true, :allow_blank => true,
        :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100,
        :message => SKILL_ERRORS[diff][ERROR_RATE_OUT_OF_RANGE]
    end

    def validate_esy_point_range; return validate_point_range(MUSIC_DIFF_ESY) end
    def validate_std_point_range; return validate_point_range(MUSIC_DIFF_STD) end
    def validate_hrd_point_range; return validate_point_range(MUSIC_DIFF_HRD) end
    def validate_mas_point_range; return validate_point_range(MUSIC_DIFF_MAS) end
    def validate_unl_point_range; return validate_point_range(MUSIC_DIFF_UNL) end

    def validate_point_range(diff)
      if music.exist?(diff) or point(diff).blank?
        return true
      end
      bonus_rate = (ultimate?(diff) ? BONUS_RATE_ULTIMATE : (survival?(diff) ? BONUS_RATE_SURVIVAL : 1.0))
      unless point(diff) >= 0.0 and point(diff) <= music.level(diff) * bonus_rate
        errors.add("#{MUSIC_DIFF_PREFIXES[diff]}_point".to_sym, SKILL_ERRORS[diff][ERROR_RP_OUT_OF_RANGE])
        return false
      else
        return true
      end
    end

    @@mode = nil
    @@ignore_locked = false

    def self.mode=(mode)
      @@mode = mode
    end

    def music_diffs
      return MUSIC_DIFFS[@@mode]
    end

    def self.ignore_locked=(ignore_locked)
      @@ignore_locked = ignore_locked
    end

    def self.ignore_locked
      return @@ignore_locked
    end

    def self.last_modified(user)
      skill = self.find(:first, :conditions => {:user_id => user.id}, :order => 'updated_at desc')
      return (skill ? skill.updated_at : nil)
    end

    def self.find_by_user(user, options={})
      skills = self.find(:all, :conditions => {:user_id => user.id})
      if options[:fill_empty]
        musics = Music.find(:all, :conditions => {:display => true})
        musics.each do |music|
          unless Skill.exists?({:user_id => user.id, :music_id => music.id})
            skill = Skill.new
            skill.music = music
            skills << skill
          end
        end
      end
      return skills
    end

    def self.find_by_user_and_music(user, music)
      skill = self.find(:first, :conditions => {:user_id => user.id, :music_id => music.id})
      unless skill
        skill = self.new
        skill.user_id = user.id
        skill.music = music
      end
      return skill
    end

    def stat(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_stat")
    end

    def point(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_point")
    end

    def rate(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_rate")
    end

    def rate_f(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f")
    end

    def rank(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_rank")
    end

    def combo(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_combo")
    end

    def gauge(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge")
    end

    def locked(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_locked")
    end

    def point_before_type_cast(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_point_before_type_cast")
    end

    def rate_before_type_cast(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_before_type_cast")
    end

    def cleared?(diff)
      return stat(diff) == SP_STATUS_CLEAR
    end

    def failed?(diff)
      return stat(diff) == SP_STATUS_FAILED
    end

    def fullcombo?(diff)
      return [SP_COMBO_STATUS_FC, SP_COMBO_STATUS_EX].include?(combo(diff))
    end

    def survival?(diff)
      if @@mode == MODE_CXB
        return false
      else
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge") == SP_GAUGE_SURVIVAL_REV
      end
    end

    def ultimate?(diff)
      if @@mode == MODE_CXB
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge") == SP_GAUGE_ULTIMATE_CXB
      else
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge") == SP_GAUGE_ULTIMATE_REV
      end
    end

    def u_rate(diff)
      unless survival?(diff) or ultimate?(diff)
        return nil
      else
        if survival?(diff)
          max_point = music.level(diff) * BONUS_RATE_SURVIVAL
        elsif ultimate?(diff)
          max_point = music.level(diff) * BONUS_RATE_ULTIMATE
        end
        return [((point(diff) || 0.0) / max_point * 100).ceil, rate(diff)].min
      end
    end

    def calc!
      send("best_diff=", nil)
      send("best_point=", 0.0)
      send("iglock_best_diff=", nil)
      send("iglock_best_point=", 0.0)

      music_diffs.keys.each do |diff|
        next unless music.exist?(diff)
        if point(diff).blank? and rate(diff)
          temp_point = music.level(diff) * ((rate(diff) ? rate(diff).to_i : 0) / 100.0)
          if survival?(diff)
            temp_point = temp_point * BONUS_RATE_SURVIVAL
          elsif ultimate?(diff)
            temp_point = temp_point * BONUS_RATE_ULTIMATE
          end
          temp_point = BigDecimal.new((temp_point * 100).to_s).truncate.to_f / 100.0
          send("#{MUSIC_DIFF_PREFIXES[diff]}_point=", temp_point)
        end
        if rate_f(diff).blank? and rate_before_type_cast(diff).instance_of?(String)
          send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f=", rate_before_type_cast(diff).match(/\A\d+\.\d+\z/).present?)
        end

        if (iglock_best_point || 0.0) < (point(diff) || 0.0)
          send("iglock_best_diff=", diff)
          send("iglock_best_point=", point(diff))
        end
        if (best_point || 0.0) < (point(diff) || 0.0) and !locked(diff)
          send("best_diff=", diff)
          send("best_point=", point(diff))
        end
      end
    end

    def rp_target=(flag)
      @target = flag
    end

    def rp_target?
      return @target
    end

    def target_diff
      return @@ignore_locked ? iglock_best_diff : (best_diff == iglock_best_diff ? best_diff : iglock_best_diff)
    end

    def target_point
      return @@ignore_locked ? iglock_best_point : best_point
    end

    def edit_uri
      return "#{SKILL_ITEM_EDIT_URI}/#{music.text_id}"
    end

    def point_to_s(diff, nlv='&ndash;')
      return cleared?(diff) ? sprintf('%.2f', point(diff)) : nlv
    end

    def point_bonus_to_s(diff, nlv='&ndash;')
      return cleared?(diff) ? sprintf('%.2f', BigDecimal((point(diff) * BONUS_RATE_UNLIMITED).to_s).floor(2)) : nlv
    end

    def point_to_input_value(diff)
      if point_before_type_cast(diff).instance_of?(String)
        return point_before_type_cast(diff)
      else
        return (point(diff) ? point_to_s(diff) : '')
      end
    end

    def rate_to_s(diff, nlv='&ndash;')
      unless cleared?(diff)
        return nlv
      else
        if rate_f(diff)
          return sprintf('%.2f%%', rate(diff))
        else
          return sprintf('%d%%', rate(diff).to_i)
        end
      end
    end

    def rate_to_input_value(diff)
      if rate_before_type_cast(diff).instance_of?(String)
        return rate_before_type_cast(diff)
      else
        return (rate(diff) ? rate_to_s(diff).gsub(/%/, '') : '')
      end
    end

    def u_rate_to_s(diff, nlv='')
      unless cleared?(diff)
        return nlv
      else
        if @@mode == MODE_REV
          mark = (survival?(diff) ? 'S' : (ultimate?(diff) ? 'U' : ''))
        else
          mark = ''
        end
        return (mark.present? ? sprintf('%s %d%%', mark, u_rate(diff)) : '')
      end
    end

    def <=>(other)
      if @@ignore_locked
        if (iglock_best_point || 0.0) != (other.iglock_best_point || 0.0)
          return -((iglock_best_point || 0.0) <=> (other.iglock_best_point || 0.0))
        else
          return music.sort_key <=> other.music.sort_key
        end
      else
        if (best_point || 0.0) != (other.best_point || 0.0)
          return -((best_point || 0.0) <=> (other.best_point || 0.0))
        elsif (iglock_best_point || 0.0) != (other.iglock_best_point || 0.0)
          return -((iglock_best_point || 0.0) <=> (other.iglock_best_point || 0.0))
        else
          return music.sort_key <=> other.music.sort_key
        end
      end
    end
  end

  class CourseSkill < ActiveRecord::Base
    include Comparable
    belongs_to :course

    validates_format_of :point_before_type_cast,
      :allow_nil => true, :allow_blank => true,
      :with => /\A\d+(\.\d+)?\z/, :message => ERRORS[ERROR_RP_NOT_NUMERIC]
    validate :validate_point_range
    validates_presence_of :rate,
      :if => (lambda do |a| a.played? and a.point.blank? end),
      :message => ERRORS[ERROR_RP_AND_RATE_NOT_EXIST]
    validates_format_of :rate_before_type_cast,
      :allow_nil => true, :allow_blank => true,
      :with => /\A\d+(\.\d+)?\z/, :message => ERRORS[ERROR_RATE_NOT_NUMERIC]
    validates_numericality_of :rate,
      :allow_nil => true, :allow_blank => true,
      :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100,
      :message => ERRORS[ERROR_RATE_OUT_OF_RANGE]

    def validate_point_range
      if point.blank?
        return true
      end
      unless point >= 0.0 and point <= course.level
        errors.add(:point, ERRORS[ERROR_RP_OUT_OF_RANGE])
        return false
      else
        return true
      end
    end

    def self.last_modified(user)
      skill = self.find(:first, :conditions => {:user_id => user.id}, :order => 'updated_at desc')
      return (skill ? skill.updated_at : nil)
    end

    def self.find_by_user(user, options={})
      skills = self.find(:all, :conditions => {:user_id => user.id})
      if options[:fill_empty]
        courses = Course.find(:all, :conditions => {:display => true})
        courses.each do |course|
          unless CourseSkill.exists?({:user_id => user.id, :course_id => course.id})
            skill = CourseSkill.new
            skill.course = course
            skills << skill
          end
        end
      end
      return skills
    end

    def self.find_by_user_and_course(user, course)
      skill = self.find(:first, :conditions => {:user_id => user.id, :course_id => course.id})
      unless skill
        skill = self.new
        skill.user_id = user.id
        skill.course = course
      end
      return skill
    end

    def best_point
      return point
    end

    def iglock_best_point
      return point
    end

    def target_point
      return point
    end

    def cleared?
      return stat == SP_COURSE_STATUS_CLEAR
    end

    def played?
      return stat != SP_COURSE_STATUS_NO_PLAY
    end

    def calc!
      if played?
        if point.nil? and rate
          temp_point = course.level * ((rate || 0.0) / 100.0)
          temp_point = BigDecimal.new((temp_point * 100).to_s).truncate.to_f / 100.0
          send("point=".to_sym, temp_point)
        elsif point and rate.nil?
          send("rate=".to_sym, (point / course.level * 1000).truncate.to_f / 10.0)
        end
      end
    end

    def rp_target=(flag)
      @target = flag
    end

    def rp_target?
      return @target == true
    end

    def edit_uri
      return "#{SKILL_COURSE_ITEM_EDIT_URI}/#{course.text_id}"
    end

    def point_to_s(nlv='&ndash;')
      return (played? ? sprintf('%.2f', point) : nlv)
    end

    def point_to_input_value
      if point_before_type_cast.instance_of?(String)
        return point_before_type_cast
      else
        return (point ? point_to_s : '')
      end
    end

    def rate_to_s(nlv='&ndash;')
      return (played? ? sprintf('%.1f%%', rate) : nlv)
    end

    def rate_to_input_value()
      if rate_before_type_cast.instance_of?(String)
        return rate_before_type_cast
      else
        return (rate ? rate_to_s.gsub(/%/, '') : '')
      end
    end

    def <=>(other)
      if (best_point || 0.0) != (other.best_point || 0.0)
        return -((best_point || 0.0) <=> (other.best_point || 0.0))
      else
        return course.sort_key <=> other.course.sort_key
      end
    end
  end

  class SkillSet < Hash
    attr_accessor :last_modified, :total_point

    def self.load(mode, user, options={})
      skill_set = self.new
      Skill.ignore_locked = options[:ignore_locked]

      music_skills = Skill.find_by_user(user, options).sort
      if mode == MODE_CXB
        skill_set[MUSIC_TYPE_NORMAL] = {:skills => [], :point => 0.0}
        skill_set[MUSIC_TYPE_SPECIAL] = {:skills => [], :point => 0.0}
        music_skills.each_with_index do |skill, i|
          if skill.music.monthly?
            skill_set[MUSIC_TYPE_NORMAL][:skills] << skill
          else
            skill_set[MUSIC_TYPE_SPECIAL][:skills] << skill
          end
        end
      else
        course_skills = CourseSkill.find_by_user(user, options).sort
        skill_set[MUSIC_TYPE_REV_SINGLE] = {:skills => music_skills, :point => 0.0}
        skill_set[MUSIC_TYPE_REV_BONUS] = {:skills => [], :point => 0.0}
        skill_set[MUSIC_TYPE_REV_COURSE] = {:skills => course_skills, :point => 0.0}
      end

      skill_set.each do |type, hash|
        next if type == MUSIC_TYPE_REV_BONUS
        hash[:skills][0..(MUSIC_TYPE_ST_COUNTS[type]-1)].each do |skill|
          next if (skill.target_point || 0.0) == 0.0
          hash[:point] += skill.target_point
          skill.rp_target = true
        end
      end
      if mode == MODE_REV
        music_skills.each do |skill|
          if !skill.rp_target? and skill.cleared?(MUSIC_DIFF_UNL)
            skill_set[MUSIC_TYPE_REV_BONUS][:skills] << skill
          end
        end
        skill_set[MUSIC_TYPE_REV_BONUS][:skills].sort! do |a, b|
          if a.locked?(MUSIC_DIFF_UNL) != b.locked?(MUSIC_DIFF_UNL)
            (a.locked?(MUSIC_DIFF_UNL) ? 1 : 0) <=> (b.locked?(MUSIC_DIFF_UNL) ? 1 : 0)
          else
            -a.point(MUSIC_DIFF_UNL) <=> -b.point(MUSIC_DIFF_UNL)
          end
        end
        if user.point_direct
          skill_set[MUSIC_TYPE_REV_BONUS][:point] =
            user.point - skill_set[MUSIC_TYPE_REV_SINGLE][:point] - skill_set[MUSIC_TYPE_REV_COURSE][:point]
        else
          skill_set[MUSIC_TYPE_REV_BONUS][:skills].each do |skill|
            if Skill.ignore_locked or !skill.locked?(MUSIC_DIFF_UNL)
              skill_set[MUSIC_TYPE_REV_BONUS][:point] += skill.point(MUSIC_DIFF_UNL) * BONUS_RATE_UNLIMITED
            end
          end
          skill_set[MUSIC_TYPE_REV_BONUS][:point] = (skill_set[MUSIC_TYPE_REV_BONUS][:point] * 100.0).to_i / 100.0
        end
      end
      skill_set.last_modified = [Skill.last_modified(user), CourseSkill.last_modified(user)].compact.max
      if user.point_direct
        skill_set.total_point = user.point
      else
        skill_set.total_point = 0.0
        skill_set.each_value do |hash|
          skill_set.total_point += hash[:point]
        end
      end

      return skill_set
    end
  end

  class SkillChart < Hash
    attr_accessor :last_modified

    def self.load(mode, user)
      skill_chart = self.new

      skills = Skill.find_by_user(user, :fill_empty => true).sort
      skill_chart[:skills] = skills
      skill_chart.last_modified = Skill.last_modified(user)

      status = {
        :clear     => {:count => 0, :max_level => 0},
        :clear_mas => {:count => 0, :max_level => 0},
        :s_rank    => {:count => 0, :max_level => 0},
        :rate_100  => {:count => 0, :max_level => 0},
        :fullcombo => {:count => 0, :max_level => 0},
        :ultimate  => {:count => 0, :max_level => 0},
        :ult_mas   => {:count => 0, :max_level => 0},
      }
      skills.each do |skill|
        MUSIC_DIFFS[mode].keys.each do |diff|
          next unless skill.music.exist?(diff)
          if skill.cleared?(diff)
            update_status(status[:clear], skill.music.level(diff))
            if [MUSIC_DIFF_MAS, MUSIC_DIFF_UNL].include?(diff)
              update_status(status[:clear_mas], skill.music.level(diff))
            end
            if [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP, SP_RANK_STATUS_S].include?(skill.rank(diff))
              update_status(status[:s_rank], skill.music.level(diff))
            end
            if skill.fullcombo?(diff)
              update_status(status[:fullcombo], skill.music.level(diff))
            end
            if skill.rate(diff) == 100
              update_status(status[:rate_100], skill.music.level(diff))
            end
            if skill.ultimate?(diff)
              update_status(status[:ultimate], skill.music.level(diff))
              if [MUSIC_DIFF_MAS, MUSIC_DIFF_UNL].include?(diff)
                update_status(status[:ult_mas], skill.music.level(diff))
              end
            end
            if skill.ultimate?(diff)
              update_status(status[:ultimate], skill.music.level(diff))
              if [MUSIC_DIFF_MAS, MUSIC_DIFF_UNL].include?(diff)
                update_status(status[:ult_mas], skill.music.level(diff))
              end
            end
          end
        end
      end
      skill_chart[:status] = status

      return skill_chart
    end

    private
    def self.update_status(status, level)
      status[:count] += 1
      status[:max_level] = [status[:max_level], level].max
    end
  end
end
