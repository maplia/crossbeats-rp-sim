require 'erb'
require 'rubygems'
require 'active_record'
require 'cxbrank/util'
require 'cxbrank/const'

module CxbRank
	class Course < ActiveRecord::Base
		include Comparable
		include ErbFileRead
		include ERB::Util
		has_many :course_musics

		def notes
			sum = 0
			course_musics.each do |course_music|
				sum += course_music.music.notes(course_music.diff)
			end

			return sum
		end

		def level_to_s
			return (level == 0) ? '-' : sprintf($config.level_format, level)
		end

		def notes_to_s
			return (notes == 0) ? '???' : sprintf('%d', notes)
		end

		def to_html
			template_html = 'course/course_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def <=>(other)
			return sort_key <=> other.sort_key
		end
	end
	
	class CourseMusic < ActiveRecord::Base
		include Comparable
		include ErbFileRead
		belongs_to :music

		def to_html
			template_html = 'course/course_music_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def <=>(other)
			return seq <=> other.seq
		end
	end
end
