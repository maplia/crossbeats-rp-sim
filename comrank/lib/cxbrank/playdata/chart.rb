require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/playdata/music_skill'

module CxbRank
  module PlayData
    class Chart < Hash
      attr_accessor :last_modified

      def self.load(user)
        skill_chart = self.new

        skills = MusicSkill.find_by_user(user, :fill_empty => true).to_a
        skills.delete_if do |skill| !skill.music.display end
        if SiteSettings.cxb_mode?
          skills.sort! do |a, b| a.music.number <=> b.music.number end
        else
          skills.sort! do |a, b| a.music.sort_key <=> b.music.sort_key end
        end
        skill_chart[:skills] = skills
        skill_chart.last_modified = MusicSkill.last_modified(user)

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
          SiteSettings.music_diffs.keys.each do |diff|
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
end
