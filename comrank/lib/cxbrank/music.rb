require 'rubygems'
require 'active_record'
require 'cxbrank/const'
require 'cxbrank/course'

module CxbRank
	class Music < ActiveRecord::Base
		include Comparable
		has_many :monthlies

		def self.set_mode(mode)
			@@mode = mode
		end

		def self.last_modified
			music = self.find(:first, :order => 'updated_at desc')
			return (music ? music.updated_at : Time.now)
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
			return send("#{MUSIC_DIFFS[@@mode][diff].downcase}_level")
		end

		def notes(diff)
			return send("#{MUSIC_DIFFS[@@mode][diff].downcase}_notes")
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

		def monthly?(date=Time.now)
			monthlies.each do |monthly|
				if (monthly.span_s..monthly.span_e).include?(date)
					return true
				end
			end
			return false
		end

		def limited?
			return limited == 1
		end

		def level_to_s(diff)
			unless exist?(diff)
				return '-'
			else
				return (level(diff) == 0) ? '-' : sprintf(LEVEL_FORMATS[@@mode], level(diff))
			end
		end

		def notes_to_s(diff)
			unless exist?(diff)
				return '-'
			else
				return (notes(diff) == 0) ? '???' : sprintf('%d', notes(diff))
			end
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

	class Monthly < ActiveRecord::Base
	end

	class MusicSet < Hash
		attr_accessor :last_modified
		def self.load(mode)
			music_set = self.new
			musics = Music.find(:all, :conditions => {:display => true}).sort
			if mode == MODE_CXB
				music_set[MUSIC_TYPE_NORMAL] = []
				music_set[MUSIC_TYPE_SPECIAL] = []
				musics.each do |music|
					if music.monthly?
						music_set[MUSIC_TYPE_SPECIAL] << music
					else
						music_set[MUSIC_TYPE_NORMAL] << music
					end
				end
			else
				music_set[MUSIC_TYPE_REV_SINGLE] = musics
				courses = Course.find(:all, :conditions => {:display => true}).sort
				music_set[MUSIC_TYPE_REV_COURSE] = courses
			end
			music_set.last_modified = [Music.last_modified, Course.last_modified].max
			return music_set
		end
	end
end
