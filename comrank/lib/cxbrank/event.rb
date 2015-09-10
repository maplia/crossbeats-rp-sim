require 'rubygems'
require 'active_record'
require 'cxbrank/music'

module CxbRank
	class Event < ActiveRecord::Base
		has_many :requires

		def to_hash
			require_hash_array = []
			requires.sort.each do |require|
				require_hash_array << require.to_hash
			end

			return {
				:text_id => text_id,
				:requires => require_hash_array,
				:span => {:start => start_date, :end => end_date},
			}
		end
	end
	
	class Require < ActiveRecord::Base
		include Comparable
		belongs_to :music

		def to_hash
			return {
				:mid => music.text_id, :title => music.title, :notes => music.max_notes,
			}
		end

		def <=>(other)
			return seq <=> other.seq
		end
	end
end
