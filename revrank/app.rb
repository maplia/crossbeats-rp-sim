require '../comrank/app'
require 'rubygems'
require 'json'
require 'sinatra/cross_origin'
require 'cxbrank/const'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/skill'
require 'cxbrank/bookmarklet'

class RevRankApp < CxbRank::AppBase
  helpers do
    def course_skill_edit_page(user, &block)
      if params[:course_text_id]
        session[:course_text_id] = params[:course_text_id]
      end
      if session[:course_text_id].blank?
        haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_COURSE_IS_UNDECIDED}
      elsif (course = CxbRank::Course.find_by_param_id(session[:course_text_id])).nil?
        haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_COURSE_NOT_EXIST}
      else
        curr_skill = CxbRank::CourseSkill.find_by_user_and_course(user, course)
        temp_skill = CxbRank::CourseSkill.find_by_user_and_course(user, course)
        if params[underscore(CxbRank::CourseSkill)]
          temp_skill.attributes = params[underscore(CxbRank::CourseSkill)]
        end
        yield curr_skill, temp_skill
      end
    end

    def bookmarklet_session(&block)
      begin
        data = JSON.parse(request.body.read, {:symbolize_names => true})
        if data[:key].blank?
          jsonx :status => 401, :message => 'セッションキーが指定されていません'
        elsif (session = CxbRank::BookmarkletSession.find(:first, :conditions => {:key => data[:key]})).nil?
          jsonx :status => 401, :message => 'セッションキーが間違っています'
        else
          session.edit_count += 1
          session.save!
          yield session, data
        end
      rescue
        jsonx :status => 400, :message => $!.message
      end
    end
  end

  get "#{CxbRank::SKILL_COURSE_ITEM_EDIT_URI}/?:course_text_id?" do
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill, temp_skill|
        settings.views << '../comrank/views/course_skill_edit'
        fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
        haml :course_skill_edit, :layout => true, :locals => {
          :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title}
      end
    end
  end

  post CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill, temp_skill|
        settings.views << '../comrank/views/course_skill_edit'
        unless temp_skill.valid?
          haml :error, :layout => true,
            :locals => {:errors => temp_skill.errors, :back_uri => request.path_info}
        else
          temp_skill.calc!
          method = (params[:update].present? ? 'put' : 'delete')
          fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
          haml :course_skill_edit_conf, :layout => true, :locals => {
            :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title, :method => method}
        end
      end
    end
  end

  put CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      if params['y'].present?
        course_skill_edit_page(user) do |curr_skill, temp_skill|
          begin
            temp_skill.calc!
            temp_skill.save!
            user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:course_text_id] = nil
            redirect CxbRank::SKILL_LIST_EDIT_URI
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
          end
        end
      else
        redirect CxbRank::SKILL_COURSE_ITEM_EDIT_URI
      end
    end
  end

  delete CxbRank::SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      if params['y'].present?
        course_skill_edit_page(user) do |curr_skill, temp_skill|
          begin
            temp_skill.destroy
            user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:course_text_id] = nil
            redirect CxbRank::SKILL_LIST_EDIT_URI
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
          end
        end
      else
        redirect CxbRank::SKILL_COURSE_ITEM_EDIT_URI
      end
    end
  end

  post '/bml_login' do
    error_no = CxbRank::BookmarkAuthenticator.authenticate(params)
    if error_no != CxbRank::NO_ERROR
      jsonx :status => 401, :message => CxbRank::ERRORS[error_no]
    else
      session = CxbRank::BookmarkletSession.new
      session.user = CxbRank::User.find_by_param_id(params[:game_id])
      session.key = SecureRandom.hex(32)
      begin
        session.save!
        jsonx :status => 200, :key => session.key, :user_id => session.user.user_id
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_update_master' do
    bookmarklet_session do |session, data|
      begin
        case data[:type]
        when 'music'
          item = CxbRank::Music.create_by_request(data[:body])
          item.save!
        when 'course'
          item = CxbRank::Course.create_by_request(data[:body])
          item.save!
        else
          jsonx :status => 400, :message => "TypeError: #{data[:type]}"
        end
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_edit' do
    bookmarklet_session do |session, data|
      begin
        case data[:type]
        when 'music'
          unless (music = CxbRank::Music.find_by_lookup_key(data[:lookup_key]))
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          else
            skill = CxbRank::Skill.create_by_request(session.user, music, data[:body])
            skill.save!
          end
        when 'course'
          unless (course = CxbRank::Course.find_by_lookup_key(data[:lookup_key]))
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          else
            skill = CxbRank::CourseSkill.create_by_request(session.user, course, data[:body])
            skill.save!
          end
        else
          jsonx :status => 400, :message => "TypeError: #{data[:type]}"
        end
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_point' do
    bookmarklet_session do |session, data|
      begin
        session.user.point = data[:body][:point]
        session.user.point_direct = true
        session.user.point_updated_at = Time.now
        session.user.save!
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_logout' do
    bookmarklet_session do |session, data|
      begin
        session.destroy
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end
end
