require 'active_record'
require 'cxbrank/site_settings'

module CxbRank
  class MasterBase < ActiveRecord::Base
    self.abstract_class = true

    def self.last_modified(text_id=nil)
      if text_id.present? and (item = self.find_by_param_id(text_id))
        return item.updated_at
      else
        return self.maximum(:updated_at)
      end
    end

    def self.find_actives
      actives = self.where(:display => true)
      if SiteSettings.pivot_date.present?
        actives = actives.where('added_at <= ?', SiteSettings.pivot_date)
      end
      if SiteSettings.cxb_mode?
        actives = actives.where(:limited => false)
      end
      return actives
    end
  end
end
