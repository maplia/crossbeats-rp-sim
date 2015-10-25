require 'cxbrank/pagemaker'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/skill'
require 'cxbrank/validate'

module CxbRank
	class SkillListMaker < PageMaker
		def last_modified
			user = get_user
			return user ? user.point_updated_at : nil
		end

		private
		def page_title
			user = get_user
			return "#{user.name}さんのランクポイント表"
		end

		def get_user
			return @session ? @session[:user] : User.find_by_param_id(@params[:user_id])
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
			user = get_user
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
			user = get_user
			skill_set = SkillSet.find_by_user(user, {:ignore_locked => true})
			ignore_locked = true

			return ERB.new(read_template).result(binding)
		end
	end
end
