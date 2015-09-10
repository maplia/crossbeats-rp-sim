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

			unless @params
				music = @session[:music]
				skill = @session[:temp_skill]
			else
				text_id = @params[:text_id]
				error_no = validate_music_text_id(text_id)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end

				music = Music.find(:first, :conditions => {:text_id => text_id})
				@session[:music] = music
				skill = Skill.find(:first, :conditions => {
					:user_id => @session[:user].id, :music_id => music.id,
				})
				if skill
					@session[:before_skill] = skill
				else
					skill = Skill.new
					skill.user_id = @session[:user].user_id
					skill.music = music
				end
				@session[:temp_skill] = skill
			end
			page_title = "ランクポイント編集 [{music.full_title}]"

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

			skill = @session[:temp_skill]
			skill.comment = @params[:comment]
			$config.music_diffs.keys.each do |diff|
				music_diff_name = $config.music_diffs[diff].downcase
				skill.send("#{music_diff_name}_stat=", @params["#{music_diff_name}_stat".to_sym])
				skill.send("#{music_diff_name}_point=", @params["#{music_diff_name}_point".to_sym])
				skill.send("#{music_diff_name}_rate=", @params["#{music_diff_name}_rate".to_sym])
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

			unless @params
				course = @session[:course]
				skill = @session[:temp_skill]
			else
				text_id = @params[:text_id]
				error_no = validate_course_text_id(text_id)
				if error_no != NO_ERROR
					return make_error_page(error_no)
				end

				course = Course.find(:first, :conditions => {:text_id => text_id})
				@session[:course] = course
				skill = CourseSkill.find(:first, :conditions => {
					:user_id => @session[:user].id, :course_id => course.id,
				})
				if skill
					@session[:before_skill] = skill
				else
					skill = CourseSkill.new
					skill.user_id = @session[:user].user_id
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

	class SkillEditorDirect
		def initialize(data)
			@data = data
		end

		def execute
			if @data.nil? or @data[:game_id].nil? or @data[:lookup_key].nil? or @data[:body].nil?
				return {:status => 400}
			end
			
			user = User.find_by_param_id(@data[:game_id])
			unless user
				return {:status => 401}
			end

			lookup_key = @data[:lookup_key]
			body = @data[:body]

			case @data[:type]
			when 'music'
				music = Music.find(:first, :conditions => {:lookup_key => lookup_key})
				unless music
					return {:status => 400}
				end
				skill = Skill.find(:first,
					:conditions => {:user_id => user.id, :music_id => music.id})
				unless skill
					skill = Skill.new
					skill.user_id = user.id
					skill.music = music
				end
				body.keys.each do |diff_name|
					skill.send("#{diff_name}_stat=", body[diff_name.to_sym][:stat])
					skill.send("#{diff_name}_point=", body[diff_name.to_sym][:point])
					skill.send("#{diff_name}_rate=", body[diff_name.to_sym][:rate])
					skill.send("#{diff_name}_rank=", body[diff_name.to_sym][:rank])
					skill.send("#{diff_name}_combo=", body[diff_name.to_sym][:combo])
					skill.send("#{diff_name}_gauge=", body[diff_name.to_sym][:gauge])
				end
			when 'course'
				course = Course.find(:first, :conditions => {:lookup_key => lookup_key})
				unless course
					return {:status => 400}
				end
				skill = CourseSkill.find(:first,
					:conditions => {:user_id => user.id, :course_id => course.id})
				unless skill
					skill = CourseSkill.new
					skill.user_id = user.id
					skill.course = course
				end
				skill.stat = body[:stat]
				skill.point = body[:point]
			end
			skill.calc!

			if skill.id or skill.best_point > 0.0
				begin
					skill.save!
				rescue
					return {:status => 500}
				end
				skill_set = SkillSet.find_by_user(user)
				user.point = skill_set.total_point
				user.point_updated_at = Time.now
				begin
					user.save!
				rescue
					return {:status => 500}
				end
			end

			return {:status => 200}
		end
	end
end
