require 'active_record'
require 'cxbrank/site_settings'
require 'cxbrank/user'

module CxbRank
  module PlayData
    class Base < ActiveRecord::Base
      include Comparable
      self.abstract_class = true
      belongs_to :user

      def deleted_music?
        if !self.is_a?(CxbRank::PlayData::MusicSkill)
          return false
        elsif SiteSettings.rev_sunrise_mode? and user.legacy
          return music.deleted? && music.deleted_at < (SiteSettings.service_end || Date.new('9999-12-31'))
        else
          return music.deleted?
        end
      end
    end
  end
end
