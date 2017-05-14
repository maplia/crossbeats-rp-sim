require 'active_record'
require 'cxbrank/master/base'
require 'cxbrank/master/music'

module CxbRank
  module Master
    class Monthly < Base
      belongs_to :music

      def self.last_modified
        return self.maximum(:updated_at)
      end

      def self.get_csv_columns
        return [
          {:name => :text_id,   :unique => true, :dump => true, :foreign => Music},
          {:name => :span_s,    :unique => true, :dump => true},
          {:name => :span_e,                     :dump => true},
        ]
      end
    end
  end
end
