require '../comrank/app'
require 'cxbrank/const'
require 'cxbrank/skill'

class RevRankApp < CxbRank::AppBase
  helpers do
    def course_skill_edit_page(user, &block)
      course_text_id = (session[:course_text_id] || params[:course_text_id])
      if course_text_id.blank?
        haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_COURSE_IS_UNDECIDED}
      elsif (course = CxbRank::Course.find_by_param_id(course_text_id)).nil?
        haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_COURSE_NOT_EXIST}
      else
        curr_skill = CxbRank::CourseSkill.find_by_user_and_course(user, course)
        yield curr_skill
      end
    end
  end

  get "#{CxbRank::SKILL_COURSE_ITEM_EDIT_URI}/:course_text_id" do
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill|
        settings.views << '../comrank/views/course_skill_edit'
        session[:course_text_id] = params[:course_text_id]
        session[:temp_skill] = curr_skill.dup
        fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
        haml :course_skill_edit, :layout => true, :locals => {
          :curr_skill => curr_skill, :temp_skill => session[:temp_skill], :fixed_title => fixed_title}
      end
    end
  end

  get CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill|
        settings.views << '../comrank/views/course_skill_edit'
        fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
        haml :course_skill_edit, :layout => true, :locals => {
          :curr_skill => curr_skill, :temp_skill => session[:temp_skill], :fixed_title => fixed_title}
      end
    end
  end

  post CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill|
        settings.views << '../comrank/views/course_skill_edit'
        session[:temp_skill].attributes = params[underscore(CxbRank::CourseSkill)]
        unless session[:temp_skill].valid?
          haml :error, :layout => true,
            :locals => {:errors => session[:temp_skill].errors, :back_uri => request.path_info}
        else
          session[:temp_skill].calc!
          method = (params[:update].present? ? 'put' : 'delete')
          fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
          haml :course_skill_edit_conf, :layout => true, :locals => {
            :curr_skill => curr_skill, :temp_skill => session[:temp_skill], :fixed_title => fixed_title, :method => method}
        end
      end
    end
  end

  put CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      if params['y'].present?
#          begin
          session[:temp_skill].save!
          user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
          user.point_direct = false
          user.point_updated_at = Time.now
          user.save!
          session[:course_text_id] = nil
          redirect CxbRank::SKILL_LIST_EDIT_URI
#          rescue
#            haml :error, :layout => true,
#              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
#          end
      else
        redirect CxbRank::SKILL_COURSE_ITEM_EDIT_URI
      end
    end
  end

  delete CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      if params['y'].present?
#          begin
          session[:temp_skill].destroy
          user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
          user.point_direct = false
          user.point_updated_at = Time.now
          user.save!
          session[:course_text_id] = nil
          redirect CxbRank::SKILL_LIST_EDIT_URI
#          rescue
#            haml :error, :layout => true,
#              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
#          end
      else
        redirect CxbRank::SKILL_COURSE_ITEM_EDIT_URI
      end
    end
  end
end
