require 'cxbrank/const'
require 'cxbrank/playdata/music_skill'
require 'cxbrank/user'
require 'cxbrank/adversary'

class Array
  def rank
    return self.map do |v| self.count do |a| a > v end + 1 end
  end
end

module CxbRank
  module PlayData
    include Comparable

    class AdversarySkill < PlayData::MusicSkill
      @@diff = nil

      def self.find_by_user_and_music_and_diff(user, music, diff)
        skills = []
        skill = self.find_by_user_and_music(user, music)
        skills << skill
        Adversary.find_all(user).each do |adversary|
          skill = self.find_by_user_and_music(adversary.adversary, music)
          skills << skill
        end
        @@diff = diff
        return skills
      end

      def stat_
        return stat(@@diff)
      end

      def rate_
        return rate(@@diff)
      end

      def rate_f_
        return rate_f(@@diff)
      end

      def rank_
        return rank(@@diff)
      end

      def combo_
        return combo(@@diff)
      end

      def survival_?
        return survival?(@@diff)
      end

      def ultimate_?
        return ultimate?(@@diff)
      end

      def fullcombo_?
        return fullcombo?(@@diff)
      end

      def score_
        return score(@@diff)
      end

      def score_rate
        return score_ / (music.notes(@@diff) * 100).to_f
      end

      def <=>(other)
        return (score_ || 0) <=> (other.score_ || 0)
      end
    end
  end
end
