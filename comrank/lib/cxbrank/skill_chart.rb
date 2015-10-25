require 'erb'
require 'cxbrank/util'
require 'cxbrank/pagemaker'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/skill'
require 'cxbrank/validate'

module CxbRank
	class SkillChartMaker < PageMaker
		include UserIdValidator
		
		def initialize(params)
			@params = params
			@template_html = 'skill/skill_chart.html.erb'
		end

		def last_modified
			return Skill.last_modified(User.find_by_param_id(@params[:user_id]))
		end

		def to_html
			error_no = validate_user_id(@params[:user_id])
			if error_no != NO_ERROR
				return make_error_page(error_no)
			end

			user = User.find_by_param_id(@params[:user_id])
			musics = Music.find(:all)
			skills = Skill.find(:all, :conditions => {:user_id => user.id})
			musics.each do |music|
				unless Skill.exists?({:user_id => user.id, :music_id => music.id})
					skill = Skill.new
					skill.music = music
					skills << skill
				end
			end
			skills.sort! do |a, b| a.music <=> b.music end

			cleared_stage_count = 0
			cleared_master_count = 0
			fullcombo_stage_count = 0
			ultimate_stage_count = 0
			srank_stage_count = 0
			cleared_max_level = 0
			fullcombo_max_level = 0
			ultimate_max_level = 0
			sprank_max_level = 0
			rate_max_count = 0
			rate_max_level = 0
			ultimate_master_count = 0
			ultimate_master_max_level = 0

			skills.each do |skill|
				$config.music_diffs.keys.each do |diff|
					next unless skill.music.exist?(diff)

					stage_level = skill.music.level(diff)

					if skill.cleared?(diff)
						# クリア譜面数
						cleared_stage_count += 1
						# クリア最高レベル
						cleared_max_level = stage_level if stage_level > cleared_max_level
						# MASTER以上クリア曲数
						if diff == MUSIC_DIFF_MAS or diff == MUSIC_DIFF_UNL
							cleared_master_count += 1
						end
						# ULTIMATEクリア譜面数
						if skill.ultimate?(diff)
							ultimate_stage_count += 1
							# ULTIMATEクリア最高レベル
							ultimate_max_level = stage_level if stage_level > ultimate_max_level
							# MASTER以上ULTIMATEクリア曲数
							if diff == MUSIC_DIFF_MAS or diff == MUSIC_DIFF_UNL
								ultimate_master_count += 1
								# ULTIMATEクリア最高レベル
								ultimate_master_max_level = stage_level if stage_level > ultimate_master_max_level
							end
						end
						# フルコンボ譜面数
						if skill.fullcombo?(diff)
							fullcombo_stage_count += 1
							# フルコンボ最高レベル
							fullcombo_max_level = stage_level if stage_level > fullcombo_max_level
						end
						# 100%クリア譜面数
						if skill.rate(diff) == 100
							rate_max_count += 1
							# フルコンボ最高レベル
							rate_max_level = stage_level if stage_level > rate_max_level
						end
						# Sランク取得譜面数
						if [SP_RANK_STATUS_SPP, SP_RANK_STATUS_SP, SP_RANK_STATUS_S].include?(skill.rank(diff))
							srank_stage_count += 1
							# S+ランク取得最高レベル
							if skill.rank(diff) != SP_RANK_STATUS_S
								sprank_max_level = stage_level if stage_level > sprank_max_level
							end
						end
					end
				end
			end
			page_title = "#{user.name}さんのクリア状況表"

			return ERB.new(read_template).result(binding)
		end
	end
end
