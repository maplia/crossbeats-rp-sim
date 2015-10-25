require 'cxbrank/util'
require 'cxbrank/pagemaker'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/skill'
require 'cxbrank/validate'

module CxbRank
	class SkillEditFormMaker < PageMaker
		include MusicTextIdValidator

		def initialize(params, session)
			@params = params
			@session = session
			@template_html = 'skill/skill_edit.html.erb'
		end

		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			if @session[:music]
				music = @session[:music]
			else
				text_id = @params[:text_id]
				error_no = validate_music_text_id(text_id)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end

				music = Music.find(:first, :conditions => {:text_id => text_id})
				@session[:music] = music
			end

			before_skill = Skill.find(:first, :conditions => {
				:user_id => @session[:user].id, :music_id => music.id,
			})

			if @session[:temp_skill]
				skill = @session[:temp_skill]
			else
				if before_skill
					skill = before_skill
				else
					skill = Skill.new
					skill.user_id = @session[:user].id
					skill.music = music
				end
				@session[:temp_skill] = skill
			end

			page_title = "ランクポイント編集 [#{music.full_title}]"

			return ERB.new(read_template).result(binding)
		end
	end

	class SkillEditCertifier < PageMaker
		def initialize(params, session)
			@params = params
			@session = session
			@template_html = 'skill/skill_edit_conf.html.erb'
		end
		
		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			before_skill = Skill.find(:first, :conditions => {
				:user_id => @session[:user].id, :music_id => @session[:music].id,
			})

			skill = @session[:temp_skill]
			skill.comment = @params[:comment]
			$config.music_diffs.keys.each do |diff|
				music_diff_name = $config.music_diffs[diff].downcase
				skill.send("#{music_diff_name}_stat=", @params["#{music_diff_name}_stat".to_sym])
				skill.send("#{music_diff_name}_point=", @params["#{music_diff_name}_point".to_sym])
				skill.send("#{music_diff_name}_rate=", @params["#{music_diff_name}_rate".to_sym])
				if @params["#{music_diff_name}_rate".to_sym] and !@params["#{music_diff_name}_rate".to_sym].is_i?
					skill.send("#{music_diff_name}_rate_f=", 1)
				else
					skill.send("#{music_diff_name}_rate_f=", 0)
				end
				skill.send("#{music_diff_name}_rank=", @params["#{music_diff_name}_rank".to_sym])
				skill.send("#{music_diff_name}_combo=", @params["#{music_diff_name}_combo".to_sym])
				if @params["#{music_diff_name}_locked".to_sym]
					skill.send("#{music_diff_name}_locked=", @params["#{music_diff_name}_locked".to_sym])
				else
					skill.send("#{music_diff_name}_locked=", 0)
				end
				skill.send("#{music_diff_name}_gauge=", @params["#{music_diff_name}_gauge".to_sym])
			end
			skill.calc!
			@session[:temp_skill] = skill

			error_no = skill.validate
			if error_no != NO_ERROR
				return make_error_page(error_no, SKILL_ITEM_EDIT_URI)
			end

			if @params[:update]
				@session[:operation] = OPERATION_UPDATE
			else
				@session[:operation] = OPERATION_DELETE
			end
			page_title = "ランクポイント編集確認 [{skill.music.full_title}]"

			return ERB.new(read_template).result(binding)
		end
	end

	class SkillEditRegistrar < PageMaker
		def initialize(session)
			@session = session
		end

		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			skill = @session[:temp_skill]
			if @session[:operation] == OPERATION_UPDATE
				unless skill.validate == NO_ERROR
					return make_error_page(ERROR_INVALID_ACCESS)
				end
				begin
					skill.save!
				rescue
					return make_error_page(ERROR_DATABASE_SAVE_FAILED, ENV['PATH_INFO'])
				end
			else
				skill.destroy
			end

			user = @session[:user]
			user.point_direct = false
			skill_set = SkillSet.find_by_user(user)
			user.point = skill_set.total_point
			user.point_updated_at = Time.now
			begin
				user.save!
			rescue
				return make_error_page(ERROR_DATABASE_SAVE_FAILED, ENV['PATH_INFO'])
			end

			@session[:music] = nil
			@session[:before_skill] = nil
			@session[:temp_skill] = nil

			return SKILL_LIST_EDIT_URI
		end
	end

	class CourseSkillEditFormMaker < PageMaker
		include CourseTextIdValidator

		def initialize(params, session)
			@params = params
			@session = session
			@template_html = 'course/course_skill_edit.html.erb'
		end

		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			if @session[:course]
				course = @session[:course]
			else
				text_id = @params[:text_id]
				error_no = validate_course_text_id(text_id)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end

				course = Course.find(:first, :conditions => {:text_id => text_id})
				@session[:course] = course
			end

			before_skill = CourseSkill.find(:first, :conditions => {
				:user_id => @session[:user].id, :course_id => course.id,
			})

			if @session[:temp_skill]
				skill = @session[:temp_skill]
			else
				if before_skill
					skill = before_skill
				else
					skill = CourseSkill.new
					skill.user_id = @session[:user].id
					skill.course = course
				end
				@session[:temp_skill] = skill
			end

			page_title = "ランクポイント編集 [{course.name}]"

			return ERB.new(read_template).result(binding)
		end
	end

	class CourseSkillEditCertifier < PageMaker
		def initialize(params, session)
			@params = params
			@session = session
			@template_html = 'course/course_skill_edit_conf.html.erb'
		end
		
		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			before_skill = CourseSkill.find(:first, :conditions => {
				:user_id => @session[:user].id, :course_id => @session[:course].id,
			})

			skill = @session[:temp_skill]
			skill.comment = @params[:comment]
			skill.stat = @params[:stat]
			skill.point = @params[:point]
			skill.rate = @params[:rate]
			skill.combo = @params[:combo]
			skill.calc!
			@session[:temp_skill] = skill

			error_no = skill.validate
			if error_no != NO_ERROR
				return make_error_page(error_no, SKILL_COURSE_ITEM_EDIT_URI)
			end

			if @params[:update]
				@session[:operation] = OPERATION_UPDATE
			else
				@session[:operation] = OPERATION_DELETE
			end
			page_title = "ランクポイント編集確認 [{skill.course.full_title}]"

			return ERB.new(read_template).result(binding)
		end
	end

	class CourseSkillEditRegistrar < SkillEditRegistrar
	end
end
