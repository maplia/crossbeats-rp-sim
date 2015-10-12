require 'erb'
require 'cxbrank/util'
require 'cxbrank/pagemaker'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/event'

module CxbRank
	class MusicListMaker < PageMaker
		def initialize
			@template_html = 'music/music_list.html.erb'
		end

		def last_modified
			updated_at_array = []
			updated_at_array << Music.last_modified if Music.last_modified
			if $config.rev_mode?
				updated_at_array << Course.last_modified if Course.last_modified
			end

			return updated_at_array.max
		end

		def to_html
			musics = Music.find(:all).sort

			music_hash = {}
			if $config.rev_mode?
				music_hash[MUSIC_TYPE_REV_SINGLE] = musics
				music_hash[MUSIC_TYPE_REV_COURSE] = Course.find(:all).sort
				music_hash[MUSIC_TYPE_REV_BONUS] = []
			else
				music_hash[MUSIC_TYPE_NORMAL] = []
				music_hash[MUSIC_TYPE_SPECIAL] = []
				musics.each do |music|
					if music.monthly?
						music_hash[MUSIC_TYPE_SPECIAL] << music
					elsif !music.limited?
						music_hash[MUSIC_TYPE_NORMAL] << music
					end
				end
			end

			page_title = '登録曲リスト'

			return ERB.new(read_template).result(binding)
		end
	end

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
