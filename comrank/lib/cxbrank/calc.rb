require 'erb'
require 'cxbrank/pagemaker'
require 'cxbrank/music'

module CxbRank
	class RankCalculatorMaker < PageMaker
		def initialize
			@template_html = 'calc/calc_rank.html.erb'
		end

		def last_modified
			return Music.last_modified
		end

		def to_html
			musics = Music.find(:all).sort
			data = []
			musics.each do |music|
				data << music.to_hash
			end
			diffs = []
			$config.music_diffs.keys.sort.each do |music_diff|
				diffs << $config.music_diffs[music_diff].downcase
			end
			page_title = '許容ミス数計算機'
			return ERB.new(read_template).result(binding)
		end
	end
end
