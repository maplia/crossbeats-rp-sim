require 'rubygems'
require 'active_record'
require 'cxbrank/const'

module CxbRank
  class User < ActiveRecord::Base
    validates_presence_of :name, :message => ERRORS[ERROR_USERNAME_IS_UNINPUTED]
    validates_presence_of :password, :message => ERRORS[ERROR_PASSWORD1_IS_UNINPUTED]
    validates_confirmation_of :password, :message => ERRORS[ERROR_PASSWORDS_ARE_NOT_EQUAL]
    validates_format_of :game_id, :allow_nil => true, :allow_blank => true,
      :with => /\A\d+\z/, :message => ERRORS[ERROR_GAME_ID_NOT_NUMERIC]
    validates_length_of :game_id, :allow_nil => true, :allow_blank => true,
      :is => GAME_ID_FIGURE, :message => ERRORS[ERROR_GAME_ID_LENGTH_IS_INVALID]
    validates_format_of :point_before_type_cast, :allow_nil => true, :allow_blank => true,
      :with => /\A\d+(\.\d+)?\z/, :message => ERRORS[ERROR_REAL_RP_NOT_NUMERIC]
    validates_presence_of :point, :if => (lambda do |a| @@mode == MODE_REV and a.id end),
      :message => ERRORS[ERROR_REAL_RP_IS_UNINPUTED]

    @@mode = nil

    def self.mode=(mode)
      @@mode = mode
    end

    def self.last_modified
      user = self.find(:first, :order => 'updated_at desc')
      return (user ? user.updated_at : Time.now)
    end

    def self.find_by_param_id(param_id)
      if param_id.size == USER_ID_FIGURE
        return self.find_by_id(param_id.to_i)
      else
        return self.find(:first,
          :conditions => {:game_id => param_id}, :order => 'point_updated_at desc')
      end
    end

    def user_id
      return sprintf('%0*d', USER_ID_FIGURE, id)
    end

    def skill_view_uri
      return "#{SKILL_LIST_VIEW_URI}/#{user_id}"
    end

    def skill_ignore_uri
      return "#{SKILL_LIST_VIEW_IGLOCK_URI}/#{user_id}"
    end

    def skill_chart_uri
      return "#{CLEAR_LIST_VIEW_URI}/#{user_id}"
    end

    def to_hash
      return {
        :user_id => user_id, :name => name,
      }
    end

    def <=>(other)
      return (point_updated_at || Time.parse('1970-01-01')) <=> (other.point_updated_at || Time.parse('1970-01-01'))
    end
  end
end
