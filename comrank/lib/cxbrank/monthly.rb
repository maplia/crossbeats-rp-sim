require 'active_record'

module CxbRank
  class Monthly < ActiveRecord::Base
    def self.last_modified
      return self.maximum(:updated_at)
    end
  end
end
