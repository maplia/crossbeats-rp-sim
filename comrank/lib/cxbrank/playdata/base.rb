require 'active_record'
require 'cxbrank/site_settings'
require 'cxbrank/user'

module CxbRank
  module PlayData
    class Base < ActiveRecord::Base
      include Comparable
      self.abstract_class = true
      belongs_to :user
    end
  end
end
