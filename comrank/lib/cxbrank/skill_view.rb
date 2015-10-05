require 'cxbrank/pagemaker'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/skill'
require 'cxbrank/validate'

module CxbRank
	class SkillListMaker < PageMaker
		private
		def page_title
			user = (@session ? @session[:user] : User.find(@params[:user_id].to_i))
			return "#{user.name}さんのランクポイント表"
		end
		
		def last_data_modified
			user_id = (@session ? @session[:user].user_id : @params[:user_id])
			updated_at_array = []
			music_skills = Skill.find(:all, :conditions => {:user_id => user_id})
			updated_at_array << music_skills.max.updated_at unless music_skills.empty?
			if $config.rev_mode?
				course_skills = CourseSkill.find(:all, :conditions => {:user_id => user_id})
				updated_at_array << course_skills.max.updated_at unless course_skills.empty?
			end

			return updated_at_array.max
		end
	end

	class SkillEditListMaker < SkillListMaker
		def initialize(session)
			@session = session
			@edit = true
			@template_html = 'skill/skill_list.html.erb'
		end

		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			user = @session[:user]
			skill_set = SkillSet.find_by_user(user, {:fill_empty => true})
			ignore_locked = false

			return ERB.new(read_template).result(binding)
		end
	end

	class SkillViewListMaker < SkillListMaker
		include UserIdValidator

		def initialize(params)
			@params = params
			@edit = false
			@template_html = 'skill/skill_list.html.erb'
		end

		def last_modified
			return last_data_modified
		end

		def to_html
			error_no = validate_user_id(@params[:user_id])
			if error_no != NO_ERROR
				return make_error_page(error_no)
			end

			user = User.find(@params[:user_id].to_i)
			skill_set = SkillSet.find_by_user(user)
			ignore_locked = false

			return ERB.new(read_template).result(binding)
		end
	end

	class SkillIgLockListMaker < SkillViewListMaker
		def to_html
			error_no = validate_user_id(@params[:user_id])
			if error_no != NO_ERROR
				return make_error_page(error_no)
			end

			user = User.find(@params[:user_id].to_i)
			skill_set = SkillSet.find_by_user(user, {:ignore_locked => true})
			ignore_locked = true

			return ERB.new(read_template).result(binding)
		end
	end
end
