require 'active_record'
require 'cxbrank/user'

module CxbRank
  class Adversary < ActiveRecord::Base
    belongs_to :user
    belongs_to :adversary, :class_name => 'User'

    def crosslink?
      return self.class.registered?(adversary, user)
    end

    def self.find_all(user)
      return self.where(:user_id => user.id)
    end

    def self.find_followings(user)
      return self.where(:user_id => user.id)
    end

    def self.find_followers(user)
      return self.where(:adversary_id => user.id)
    end

    def self.registered?(user, adversary)
      return self.exists?({:user_id => user.id, :adversary_id => adversary.id})
    end
  end
end
