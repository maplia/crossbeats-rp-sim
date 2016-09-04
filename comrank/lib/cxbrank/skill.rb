require 'rubygems'
require 'active_record'
require 'bigdecimal'
require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/user'
require 'cxbrank/music'

module CxbRank
  class Skill < ActiveRecord::Base
    include Comparable
    belongs_to :music
    belongs_to :user

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
        :if => (lambda do |a| a.rate_before_type_cast(diff) =~ /\A\d+(\.\d+)?\z/ end),
        :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100,
        :message => SKILL_ERRORS[diff][ERROR_RATE_OUT_OF_RANGE]
      validates_format_of "#{diff_prefix}_score_before_type_cast".to_sym,
        :allow_nil => true, :allow_blank => true,
        :with => /\A\d+\z/, :message => SKILL_ERRORS[diff][ERROR_SCORE_NOT_NUMERIC]
      validate "validate_#{diff_prefix}_score_range".to_sym
    end

    def validate_esy_point_range; return validate_point_range(MUSIC_DIFF_ESY) end
    def validate_std_point_range; return validate_point_range(MUSIC_DIFF_STD) end
    def validate_hrd_point_range; return validate_point_range(MUSIC_DIFF_HRD) end
    def validate_mas_point_range; return validate_point_range(MUSIC_DIFF_MAS) end
    def validate_unl_point_range; return validate_point_range(MUSIC_DIFF_UNL) end
    def validate_esy_score_range; return validate_score_range(MUSIC_DIFF_ESY) end
    def validate_std_score_range; return validate_score_range(MUSIC_DIFF_STD) end
    def validate_hrd_score_range; return validate_score_range(MUSIC_DIFF_HRD) end
    def validate_mas_score_range; return validate_score_range(MUSIC_DIFF_MAS) end
    def validate_unl_score_range; return validate_score_range(MUSIC_DIFF_UNL) end

    def validate_point_range(diff)
      level = (legacy(diff) ? music.legacy_level(diff) : music.level(diff))
      if level.blank? or point(diff).blank? or point_before_type_cast(diff) !~ /\A\d+(\.\d+)?\z/
        return true
      end
      bonus_rate = gauge_bonus_rate(diff)
      if (point(diff) < 0.0) or (point(diff) > level * bonus_rate)
        errors.add("#{MUSIC_DIFF_PREFIXES[diff]}_point".to_sym, SKILL_ERRORS[diff][ERROR_RP_OUT_OF_RANGE])
        return false
      else
        return true
      end
    end

    def validate_score_range(diff)
      notes = (legacy(diff) ? music.legacy_notes(diff) : music.notes(diff))
      if notes.blank? or score(diff).blank? or score_before_type_cast(diff) !~ /\A\d+\z/
        return true
      end
      if (score(diff) < 0) or (score(diff) > notes * 100)
        errors.add("#{MUSIC_DIFF_PREFIXES[diff]}_score".to_sym, SKILL_ERRORS[diff][ERROR_SCORE_OUT_OF_RANGE])
        return false
      else
        return true
      end
    end

    @@date = nil
    @@ignore_locked = false

    def self.date=(date)
      @@date = date
    end

    def self.ultimate_enable?
      return (@@date || Time.now) >= ULTIMATE_START_DATE[@@mode]
    end

    def self.ignore_locked=(ignore_locked)
      @@ignore_locked = ignore_locked
    end

    def self.ignore_locked
      return @@ignore_locked
    end

    def self.last_modified(user)
      return self.where(:user_id => user.id).maximum(:updated_at)
    end

    def self.find_by_user(user, options={})
      skills = self.where(:user_id => user.id)
      if SiteSettings.cxb_mode?
        skills = skills.joins(:music).where('musics.limited = ?', false)
      end
      if options[:fill_empty]
        omit_music_ids = (skills.pluck(:music_id).empty? ? [0] : skills.pluck(:music_id))
        empty_musics = Music.find_actives.where('id not in (?)', omit_music_ids)
        empty_musics.each do |music|
          skill = Skill.new
          skill.user_id = user.id
          skill.music = music
          skills << skill
        end
      else
        skills = skills.to_a
        skills.delete_if do |skill| !skill.played? end
      end
      return skills
    end

    def self.find_by_user_and_music(user, music)
      skill = self.where(:user_id => user.id, :music_id => music.id).first
      unless skill
        skill = self.new
        skill.user_id = user.id
        skill.music = music
      end
      return skill
    end

    def self.max(mode, music, date=nil)
      max_diff = (music.exist?(MUSIC_DIFF_UNL) ? MUSIC_DIFF_UNL : MUSIC_DIFF_MAS)
      skill = self.new
      skill.music = music
      skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_stat=", SP_STATUS_CLEAR)
      skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_rate=", 100)
      skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_rate_f=", false)
      skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_rank=", SP_RANK_STATUS_SPP)
      skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_combo=", SP_COMBO_STATUS_EX)
      if date.nil? or (date.present? and date >= ULTIMATE_START_DATE[mode])
        skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_gauge=", (mode == MODE_CXB ? SP_GAUGE_ULTIMATE_CXB : SP_GAUGE_ULTIMATE_REV))
      end
      if max_diff == MUSIC_DIFF_UNL and music.unlock_unl == UNLOCK_UNL_TYPE_NEVER
        skill.unl_locked = true
        skill.mas_stat = SP_STATUS_CLEAR
        skill.mas_rate = 100
        skill.mas_rate_f = false
        skill.mas_rank = SP_RANK_STATUS_SPP
        skill.mas_combo = SP_COMBO_STATUS_EX
        if date.nil? or (date.present? and date >= ULTIMATE_START_DATE[mode])
          skill.mas_gauge = (mode == MODE_CXB ? SP_GAUGE_ULTIMATE_CXB : SP_GAUGE_ULTIMATE_REV)
        end
      end
      skill.calc!
      return skill
    end

    def self.create_by_request(user, music, body)
      invert_music_diffs = MUSIC_DIFF_PREFIXES.invert
      skill = self.where(:user_id => user.id, :music_id => music.id).first
      unless skill
        skill = Skill.new
        skill.user_id = user.id
        skill.music = music
      end
      body.keys.each do |prefix|
        return nil unless music.exist?(invert_music_diffs[prefix.to_s])
        skill.send("#{prefix}_stat=", body[prefix.to_sym][:stat])
        skill.send("#{prefix}_point=", body[prefix.to_sym][:point])
        skill.send("#{prefix}_rate=", body[prefix.to_sym][:rate])
        skill.send("#{prefix}_rate_f=", true)
        skill.send("#{prefix}_rank=", body[prefix.to_sym][:rank])
        skill.send("#{prefix}_combo=", body[prefix.to_sym][:combo])
        skill.send("#{prefix}_score=", body[prefix.to_sym][:score])
        skill.send("#{prefix}_gauge=", body[prefix.to_sym][:gauge])
      end
      skill.unl_locked = !skill.unlocked_unl?
      skill.calc!
      return skill
    end

    def self.get_rank_data(music, diff)
      diff_stat_column = "#{MUSIC_DIFF_PREFIXES[diff]}_stat".to_sym
      diff_score_column = "#{MUSIC_DIFF_PREFIXES[diff]}_score".to_sym
      diff_rate_column = "#{MUSIC_DIFF_PREFIXES[diff]}_rate".to_sym
      return Skill.where(:music_id => music.id).where(diff_stat_column => [SP_STATUS_FAILED, SP_STATUS_CLEAR])
        .joins(:user).where('users.display = ?', true).order(diff_score_column => :desc, diff_rate_column => :desc)
    end

    def update_by_params!(params)
      if params.present?
        self.attributes = params
      end
    end

    def played?
      SiteSettings.music_diffs.keys.each do |diff|
        return true unless stat(diff) == SP_STATUS_NO_PLAY
      end
      return false
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

    def score(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_score")
    end

    def gauge(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge")
    end

    def locked(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_locked")
    end

    def legacy(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_legacy")
    end

    def point_before_type_cast(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_point_before_type_cast")
    end

    def rate_before_type_cast(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_before_type_cast")
    end

    def score_before_type_cast(diff)
      return send("#{MUSIC_DIFF_PREFIXES[diff]}_score_before_type_cast")
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
      if SiteSettings.cxb_mode?
        return false
      else
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge") == SP_GAUGE_SURVIVAL_REV
      end
    end

    def ultimate?(diff)
      if SiteSettings.cxb_mode?
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge") == SP_GAUGE_ULTIMATE_CXB
      else
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge") == SP_GAUGE_ULTIMATE_REV
      end
    end

    def u_rate(diff)
      unless survival?(diff) or ultimate?(diff)
        return nil
      else
        level = (legacy(diff) ? music.legacy_level(diff) : music.level(diff))
        max_point = level * gauge_bonus_rate(diff)
        return [((point(diff) || 0.0) / max_point).ceil(2) * 100, rate(diff)].min
      end
    end

    def calc!
      send('best_diff=', nil)
      send('best_point=', 0.0)
      send('iglock_best_diff=', nil)
      send('iglock_best_point=', 0.0)
      @point_filled = {}
      @rate_filled = {}

      SiteSettings.music_diffs.keys.each do |diff|
        next unless music.exist?(diff) and cleared?(diff)
        level = (legacy(diff) ? music.legacy_level(diff) : music.level(diff))
        @point_filled[diff] = false
        @rate_filled[diff] = false
        if point(diff).blank? and rate(diff)
          calc_point = (level * BigDecimal.new((rate(diff).to_i / 100.0).to_s) * gauge_bonus_rate(diff)).floor(2)
          send("#{MUSIC_DIFF_PREFIXES[diff]}_point=", calc_point)
          @point_filled[diff] = true
        elsif rate(diff).blank? and point(diff)
          calc_rate = ((point(diff) / gauge_bonus_rate(diff)).ceil(2) / level).floor(2) * 100.0
          send("#{MUSIC_DIFF_PREFIXES[diff]}_rate=", calc_rate)
          send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f=", false)
          @rate_filled[diff] = true
        end
        if rate(diff).blank?
          send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f=", nil)
        elsif rate_before_type_cast(diff).instance_of?(String)
          send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f=", rate_before_type_cast(diff).match(/\A\d+\.\d+\z/).present?)
        end

        if (iglock_best_point || 0.0) < (point(diff) || 0.0)
          send('iglock_best_diff=', diff)
          send('iglock_best_point=', point(diff))
        end
        if (best_point || 0.0) < (point(diff) || 0.0) and !locked(diff)
          send('best_diff=', diff)
          send('best_point=', point(diff))
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
      return @@ignore_locked ? iglock_best_diff : (SiteSettings.music_diffs.keys.include?(best_diff) ? best_diff : iglock_best_diff)
    end

    def target_point
      return @@ignore_locked ? iglock_best_point : best_point
    end

    def edit_uri
      return SiteSettings.join_site_base(File.join(SKILL_ITEM_EDIT_URI, music.text_id))
    end

    def point_to_s(diff, nlv='&ndash;')
      return cleared?(diff) ? sprintf('%.2f', point(diff)) : nlv
    end

    def point_bonus_to_s(diff, nlv='&ndash;')
      return cleared?(diff) ? sprintf('%.2f', BigDecimal((point(diff) * BONUS_RATE_UNLIMITED).to_s).floor(2)) : nlv
    end

    def point_to_input_value(diff)
      if @point_filled and @point_filled[diff]
        return ''
      elsif point_before_type_cast(diff).instance_of?(String)
        return point_before_type_cast(diff)
      else
        return (point(diff) ? point_to_s(diff, '') : '')
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
      if @rate_filled and @rate_filled[diff]
        return ''
      elsif rate_before_type_cast(diff).instance_of?(String)
        return rate_before_type_cast(diff)
      else
        return (rate(diff) ? rate_to_s(diff, '').gsub(/%/, '') : '')
      end
    end

    def u_rate_to_s(diff, nlv='')
      unless cleared?(diff) and (survival?(diff) or ultimate?(diff))
        return nlv
      else
        if SiteSettings.rev_mode?
          mark = (survival?(diff) ? 'S' : (ultimate?(diff) ? 'U' : ''))
        else
          mark = ''
        end
        return (mark.present? ? sprintf('%s %d%%', mark, u_rate(diff)) : sprintf('%d%%', u_rate(diff)))
      end
    end

    def gauge_bonus_rate(diff)
      return (survival?(diff) ? BONUS_RATE_SURVIVAL : (ultimate?(diff) ? BONUS_RATE_ULTIMATE : BONUS_RATE_NONE))
    end

    def unlimited_bonus
      diff = MUSIC_DIFF_UNL
      if music.exist?(diff) and cleared?(diff)
        return point(diff) * BONUS_RATE_UNLIMITED
      else
        return 0.0
      end
    end

    def unlocked_unl?
      case music.unlock_unl
      when UNLOCK_UNL_TYPE_S
        return [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP, SP_RANK_STATUS_S].include?(rank(MUSIC_DIFF_MAS))
      when UNLOCK_UNL_TYPE_SP
        return [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP].include?(rank(MUSIC_DIFF_MAS))
      when UNLOCK_UNL_TYPE_FC
        return fullcombo?(MUSIC_DIFF_MAS)
      end
    end

    def to_hash
      hash = {
        :music => music.to_hash, :comment => comment,
      }
      MUSIC_DIFF_PREFIXES.keys.each do |diff|
        if music.exist?(diff)
          hash[MUSIC_DIFF_PREFIXES[diff]] = {
            :stat => stat(diff), :locked => locked(diff), :legacy => legacy(diff),
            :point => point(diff), :rate => rate(diff), :score => score(diff),
            :rank => rank(diff), :combo => combo(diff), :gauge => gauge(diff)
          }
        else
          hash[MUSIC_DIFF_PREFIXES[diff]] = {
            :stat => nil, :locked => nil,
            :point => nil, :rate => nil, :score => nil,
            :rank => nil, :combo => nil, :gauge => nil
          }
        end
      end

      return hash
    end

    def <=>(other)
      if @@ignore_locked
        if (iglock_best_point || 0.0) != (other.iglock_best_point || 0.0)
          return -((iglock_best_point || 0.0) <=> (other.iglock_best_point || 0.0))
        elsif (target_diff || 0) != (other.target_diff || 0)
          return (target_diff || 0) <=> (other.target_diff || 0)
        else
          return music.sort_key <=> other.music.sort_key
        end
      else
        if (best_point || 0.0) != (other.best_point || 0.0)
          return -((best_point || 0.0) <=> (other.best_point || 0.0))
        elsif (iglock_best_point || 0.0) != (other.iglock_best_point || 0.0)
          return -((iglock_best_point || 0.0) <=> (other.iglock_best_point || 0.0))
        elsif (target_diff || 0) != (other.target_diff || 0)
          return (target_diff || 0) <=> (other.target_diff || 0)
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
      if course.level > 0 and (point < 0.0 or point > course.level)
        errors.add(:point, ERRORS[ERROR_RP_OUT_OF_RANGE])
        return false
      else
        return true
      end
    end

    def self.last_modified(user)
      return self.where(:user_id => user.id).maximum(:updated_at)
    end

    def self.find_by_user(user, options={})
      skills = self.where(:user_id => user.id)
      if options[:fill_empty]
        courses = Course.where(:display => true)
        courses.each do |course|
          unless CourseSkill.exists?(:user_id => user.id, :course_id => course.id)
            skill = CourseSkill.new
            skill.course = course
            skills << skill
          end
        end
      else
        skills = skills.to_a
        skills.delete_if do |skill| !skill.played? end
      end
      return skills
    end

    def self.find_by_user_and_course(user, course)
      skill = self.where(:user_id => user.id, :course_id => course.id).first
      unless skill
        skill = self.new
        skill.user_id = user.id
        skill.course = course
      end
      return skill
    end

    def self.create_by_request(user, course, body)
      skill = self.where(:user_id => user.id, :course_id => course.id).first
      unless skill
        skill = self.new
        skill.user_id = user.id
        skill.course = course
      end
      skill.stat = body[:stat]
      skill.point = body[:point]
      skill.rate = body[:rate]
      skill.calc!
      return skill
    end

    def update_by_params!(params)
      if params.present?
        self.attributes = params
      end
    end

    def self.max(mode, course, date=nil)
      skill = self.new
      skill.course = course
      skill.stat = SP_STATUS_CLEAR
      skill.rate = 100
      skill.combo = SP_COMBO_STATUS_EX
      skill.calc!
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
      @point_filled = false
      @rate_filled = false
      if played?
        if point.blank? and rate and (course.level > 0)
          calc_point = (course.level * BigDecimal.new((rate / 100.0).to_s)).floor(2)
          send('point=', calc_point)
          @point_filled = true
        elsif point and rate.blank? and (course.level > 0)
          calc_rate = (point / course.level).floor(3) * 100
          send('rate=', calc_rate)
          @rate_filled = true
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
      return SiteSettings.join_site_base(File.join(SKILL_COURSE_ITEM_EDIT_URI, course.text_id))
    end

    def point_to_s(nlv='&ndash;')
      return (played? ? sprintf('%.2f', point) : nlv)
    end

    def point_to_input_value
      if @point_filled
        return ''
      elsif point_before_type_cast.instance_of?(String)
        return point_before_type_cast
      else
        return (point ? point_to_s : '')
      end
    end

    def rate_to_s(nlv='&ndash;')
      if played? and rate
        if rate_f
          return sprintf('%.2f%%', rate)
        else
          return sprintf('%d%%', rate.to_i)
        end
      else
        return nlv
      end
    end

    def rate_to_input_value()
      if @rate_filled
        return ''
      elsif rate_before_type_cast.instance_of?(String)
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

  class SkillSet
    attr_accessor :last_modified, :total_point

    def initialize(mode, user, skill_options={})
      @mode = mode
      @user = user
      @date = skill_options[:date]
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
          Skill.last_modified(@user), CourseSkill.last_modified(@user)
        ].compact.max
      else
        @music_set = MusicSet.new(@mode, @date)
        @last_modified = @music_set.last_modified
      end
    end

    def load!
      Skill.ignore_locked = @skill_options[:ignore_locked]

      music_skills = Skill.find_by_user(@user, @skill_options).sort
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
        course_skills = CourseSkill.find_by_user(@user, @skill_options).sort
        @hash[MUSIC_TYPE_REV_SINGLE] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_LIMITED] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_BONUS] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_COURSE] = {:skills => [], :point => 0.0}
        @hash[MUSIC_TYPE_REV_COURSE_LIMITED] = {:skills => [], :point => 0.0}
        music_skills.dup.each do |skill|
          if skill.music.limited
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
            if Skill.ignore_locked or !skill.locked(MUSIC_DIFF_UNL)
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
    def initialize(mode, date=nil)
      super(mode, nil, :date => date)
    end

    def load!
      @music_set.load!
      if SiteSettings.cxb_mode?
        [MUSIC_TYPE_NORMAL, MUSIC_TYPE_SPECIAL].each do |type|
          @music_set[type].each do |music|
            @hash[type][:skills] << Skill.max(@mode, music, @date)
          end
        end
      else
        @music_set[MUSIC_TYPE_REV_SINGLE].each do |music|
          @hash[MUSIC_TYPE_REV_SINGLE][:skills] << Skill.max(@mode, music, @date)
        end
        @music_set[MUSIC_TYPE_REV_COURSE].each do |course|
          @hash[MUSIC_TYPE_REV_COURSE][:skills] << CourseSkill.max(@mode, course, @date)
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

  class SkillChart < Hash
    attr_accessor :last_modified

    def self.load(mode, user)
      skill_chart = self.new

      skills = Skill.find_by_user(user, :fill_empty => true).to_a
      skills.delete_if do |skill| !skill.music.display end
      if SiteSettings.cxb_mode?
        skills.sort! do |a, b| a.music.number <=> b.music.number end
      else
        skills.sort! do |a, b| a.music.sort_key <=> b.music.sort_key end
      end
      skill_chart[:skills] = skills
      skill_chart.last_modified = Skill.last_modified(user)

      status = {
        :clear     => {:count => 0, :max_level => 0},
        :clear_mas => {:count => 0, :max_level => 0},
        :s_rank    => {:count => 0, :max_level => 0},
        :sp_rank   => {:count => 0, :max_level => 0},
        :spp_rank  => {:count => 0, :max_level => 0},
        :rate_100  => {:count => 0, :max_level => 0},
        :fullcombo => {:count => 0, :max_level => 0},
        :ultimate  => {:count => 0, :max_level => 0},
        :ult_mas   => {:count => 0, :max_level => 0},
      }
      skills.each do |skill|
        MUSIC_DIFFS[mode].keys.each do |diff|
          next unless skill.music.exist?(diff)
          level = (skill.legacy(diff) ? skill.music.legacy_level(diff) : skill.music.level(diff))
          if skill.cleared?(diff)
            update_status(status[:clear], level)
            if [MUSIC_DIFF_MAS, MUSIC_DIFF_UNL].include?(diff)
              update_status(status[:clear_mas], level)
            end
            if [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP, SP_RANK_STATUS_S].include?(skill.rank(diff))
              update_status(status[:s_rank], level)
            end
            if [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP].include?(skill.rank(diff))
              update_status(status[:sp_rank], level)
            end
            if [SP_RANK_STATUS_SPP].include?(skill.rank(diff))
              update_status(status[:spp_rank], level)
            end
            if skill.fullcombo?(diff)
              update_status(status[:fullcombo], level)
            end
            if skill.rate(diff) == 100
              update_status(status[:rate_100], level)
            end
            if skill.ultimate?(diff)
              update_status(status[:ultimate], level)
              if [MUSIC_DIFF_MAS, MUSIC_DIFF_UNL].include?(diff)
                update_status(status[:ult_mas], level)
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
