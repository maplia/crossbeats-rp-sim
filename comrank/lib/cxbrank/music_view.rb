require 'erb'
require 'cxbrank/pagemaker'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/event'

module CxbRank
	class ScoreSheetMaker < PageMaker
		def initialize(cgi)
			@params = cgi.path_params
			@mobile = cgi.mobile?
			@template_html = 'score_sheet.html.erb'
		end

		def last_modified
			musics = Music.find(:all)
			return Music.maximum('updated_at')
		end

		def to_html
			text_id = @params[1]
			section = @params[2]

			unless text_id
				return make_error_page(ERROR_EVENT_ID_IS_UNDECIDED)
			end

			event = Event.find(:first, :conditions => {:text_id => text_id})

			if event.nil? or event.requires.empty?
				return make_error_page(ERROR_EVENT_ID_NOT_EXIST)
			end

			return ERB.new(read_template).result(binding)
		end
	end
end
