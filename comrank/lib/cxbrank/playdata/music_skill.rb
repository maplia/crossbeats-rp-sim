require 'cxbrank/const'
require 'cxbrank/master/music'
require 'cxbrank/playdata/base'

module CxbRank
  module PlayData
    class MusicSkill < PlayData::Base
      self.table_name = 'skills'
      belongs_to :music, :class_name => 'Master::Music'

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
          empty_musics = Master::Music.find_actives(false).where('id not in (?)', omit_music_ids)
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
        skill = self.find_by(:user_id => user.id, :music_id => music.id)
        unless skill
          skill = self.new
          skill.user_id = user.id
          skill.music = music
        end
        return skill
      end

      def self.max(music)
        max_diff = (music.exist?(MUSIC_DIFF_UNL) ? MUSIC_DIFF_UNL : MUSIC_DIFF_MAS)
        skill = self.new
        skill.music = music
        skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_stat=", SP_STATUS_CLEAR)
        skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_rate=", 100)
        skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_rate_f=", false)
        skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_rank=", SP_RANK_STATUS_SPP)
        skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_combo=", SP_COMBO_STATUS_EX)
        if SiteSettings.ultimate_enabled?
          skill.send("#{MUSIC_DIFF_PREFIXES[max_diff]}_gauge=",
            (SiteSettings.cxb_mode? ? SP_GAUGE_ULTIMATE_CXB : SP_GAUGE_ULTIMATE_REV))
        end
        if max_diff == MUSIC_DIFF_UNL and music.unlock_unl == UNLOCK_UNL_TYPE_NEVER
          skill.unl_locked = true
          skill.mas_stat = SP_STATUS_CLEAR
          skill.mas_rate = 100
          skill.mas_rate_f = false
          skill.mas_rank = SP_RANK_STATUS_SPP
          skill.mas_combo = SP_COMBO_STATUS_EX
          if SiteSettings.ultimate_enabled?
            skill.mas_gauge = (SiteSettings.cxb_mode? ? SP_GAUGE_ULTIMATE_CXB : SP_GAUGE_ULTIMATE_REV)
          end
        end
        skill.calc!
        return skill
      end

      def self.create_by_request(user, music, body)
        invert_music_diffs = MUSIC_DIFF_PREFIXES.invert
        skill = self.find_by_user_and_music(user, music)
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
        if mas_locked || unl_locked
          return false
        else
          case music.unlock_unl
          when UNLOCK_UNL_TYPE_FREE
            return true
          when UNLOCK_UNL_TYPE_S
            return [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP, SP_RANK_STATUS_S].include?(rank(MUSIC_DIFF_MAS))
          when UNLOCK_UNL_TYPE_SP
            return [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP].include?(rank(MUSIC_DIFF_MAS))
          when UNLOCK_UNL_TYPE_FC
            return fullcombo?(MUSIC_DIFF_MAS)
          when UNLOCK_UNL_TYPE_NEVER
            return false
          end
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
  end
end