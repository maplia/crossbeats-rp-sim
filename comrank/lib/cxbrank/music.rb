require 'rubygems'
require 'active_record'
require 'cxbrank/util'
require 'cxbrank/const'

module CxbRank
	class MusicEdit < ActiveRecord::Base
		set_table_name '_musics'
	end

	class Music < ActiveRecord::Base
		include Comparable
		include ErbFileRead

		def self.last_modified
			music = self.find(:first, :order => 'updated_at desc')
			return (music ? music.updated_at : nil)
		end

		def self.find_by_param_id(param_id)
			if param_id.is_i? and params_id.to_i > 0
				return self.find(:first, :conditions => {:number => param_id.to_i})
			else
				return self.find(:first, :conditions => {:text_id => param_id})
			end
		end

		def full_title
			return subtitle ? "#{title} #{subtitle}" : title
		end

		def level(diff)
			return send("#{$config.music_diffs[diff].downcase}_level")
		end

		def notes(diff)
			return send("#{$config.music_diffs[diff].downcase}_notes")
		end

		def max_notes
			note_data = []
			$config.music_diffs.keys.each do |diff|
				note_data << notes(diff)
			end

			return note_data.max
		end

		def exist?(diff)
			return !level(diff).nil?
		end

		def monthly?
			return monthly == 1
		end

		def limited?
			return limited == 1
		end

		def level_to_s(diff)
			unless exist?(diff)
				return '-'
			else
				return (level(diff) == 0) ? '-' : sprintf($config.level_format, level(diff))
			end
		end

		def notes_to_s(diff)
			unless exist?(diff)
				return '-'
			else
				return (notes(diff) == 0) ? '???' : sprintf('%d', notes(diff))
			end
		end

		def to_html
			template_html = 'music/music_list_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_hash
			hash = {
				:text_id => text_id, :number => number,
				:title => title, :subtitle => subtitle, :full_title => full_title,
				:monthly => monthly?, :limited => limited?,
			}
			$config.music_diffs.each do |diff, diff_name|
				hash[diff_name.downcase] = {
					:level => level(diff), :notes => notes(diff),
				}
			end

			return hash
		end

		def <=>(other)
			if number != other.number
				return number <=> other.number
			else
				return sort_key <=> other.sort_key
			end
		end
	end
end
