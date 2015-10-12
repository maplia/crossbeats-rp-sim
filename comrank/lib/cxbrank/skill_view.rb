require 'cxbrank/pagemaker'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/skill'
require 'cxbrank/validate'

module CxbRank
	class SkillListMaker < PageMaker
		def last_modified
			user = (@session ? @session[:user] : User.find(@params[:user_id].to_i))
			updated_at_array = []
			updated_at_array << Skill.last_modified(user) if Skill.last_modified(user)
			if $config.rev_mode?
				updated_at_array << CourseSkill.last_modified(user) if CourseSkill.last_modified(user)
			end

			return updated_at_array.max
		end

		private
		def page_title
			user = (@session ? @session[:user] : User.find(@params[:user_id].to_i))
			return "#{user.name}さんのランクポイント表"
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

		def to_html
			error_no = validate_user_id(@params[:user_id])
			if error_no != NO_ERROR
				return make_error_page(error_no)
			end

			Skill.ignore_locked = false
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

			Skill.ignore_locked = true
			user = User.find(@params[:user_id].to_i)
			skill_set = SkillSet.find_by_user(user, {:ignore_locked => true})
			ignore_locked = true

			return ERB.new(read_template).result(binding)
		end
	end
end
