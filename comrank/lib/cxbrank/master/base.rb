require 'active_record'
require 'cxbrank/site_settings'

module CxbRank
  module Master
    class Base < ActiveRecord::Base
      include Comparable
      self.abstract_class = true

      def self.last_modified
        return self.maximum(:updated_at)
      end

      def self.find_actives(without_deleted, *order)
        actives = self.where(:display => true)
        if SiteSettings.cxb_mode?
          actives = actives.where(:limited => false)
        end
        if without_deleted
          if SiteSettings.pivot_date
            actives = actives.where('added_at <= ? and (deleted_at is null or deleted_at > ?)',
              SiteSettings.pivot_date, SiteSettings.pivot_date)
          else
            actives = actives.where(:deleted => false)
          end
        end
        return actives.order(order)
      end
    end
  end
end
