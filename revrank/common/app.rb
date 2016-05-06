$LOAD_PATH << '../../comrank/lib'
require '../../comrank/app'
require 'rubygems'
require 'json'
require 'sinatra/cross_origin'
require 'cxbrank/const'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/skill'
require 'cxbrank/bookmarklet'

class RevRankApp < CxbRank::AppBase
  include CxbRank
  helpers do
    def course_skill_edit_page(user, &block)
      if params[:course_text_id]
        session[:course_text_id] = params[:course_text_id]
      end
      if session[:course_text_id].blank?
        haml :error, :layout => true, :locals => {:error_no => ERROR_COURSE_IS_UNDECIDED}
      elsif (course = Course.find_by_param_id(session[:course_text_id])).nil?
        haml :error, :layout => true, :locals => {:error_no => ERROR_COURSE_NOT_EXIST}
      else
        curr_skill = CourseSkill.find_by_user_and_course(user, course)
        temp_skill = CourseSkill.find_by_user_and_course(user, course)
        temp_skill.update_by_params!(session[underscore(CxbRank::CourseSkill)])
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

  get "#{SKILL_COURSE_ITEM_EDIT_URI}/?:course_text_id?" do
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill, temp_skill|
        settings.views << SiteSettings.join_comrank_path('views/course_skill_edit')
        fixed_title = "#{PAGE_TITLES[SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
        haml :course_skill_edit, :layout => true, :locals => {
          :user => user, :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title}
      end
    end
  end

  post SKILL_COURSE_ITEM_EDIT_URI do
    session[underscore(CxbRank::CourseSkill)] = Hash[params[underscore(CxbRank::CourseSkill)]]
    private_page do |user|
      course_skill_edit_page(user) do |curr_skill, temp_skill|
        settings.views << SiteSettings.join_comrank_path('views/course_skill_edit')
        unless temp_skill.valid?
          haml :error, :layout => true,
            :locals => {:errors => temp_skill.errors, :back_uri => request.path_info}
        else
          temp_skill.calc!
          method = (params[:update].present? ? 'put' : 'delete')
          fixed_title = "#{PAGE_TITLES[SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
          haml :course_skill_edit_conf, :layout => true, :locals => {
            :user => user, :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title, :method => method}
        end
      end
    end
  end

  put SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      if params['y'].present?
        course_skill_edit_page(user) do |curr_skill, temp_skill|
          begin
            temp_skill.calc!
            temp_skill.save!
            skill_set = SkillSet.new(settings.site_mode, user)
            skill_set.calc!
            user.point = skill_set.total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:course_text_id] = nil
            session[underscore(CxbRank::CourseSkill)] = nil
            redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => ERROR_DATABASE_SAVE_FAILED, :back_uri => SiteSettings.join_site_base(request.path_info)}
          end
        end
      else
        redirect SiteSettings.join_site_base(SKILL_COURSE_ITEM_EDIT_URI)
      end
    end
  end

  delete SKILL_COURSE_ITEM_EDIT_URI do
    private_page do |user|
      if params['y'].present?
        course_skill_edit_page(user) do |curr_skill, temp_skill|
          begin
            temp_skill.destroy
            skill_set = SkillSet.new(settings.site_mode, user)
            skill_set.calc!
            user.point = skill_set.total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:course_text_id] = nil
            redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => ERROR_DATABASE_SAVE_FAILED, :back_uri => SiteSettings.join_site_base(request.path_info)}
          end
        end
      else
        redirect SiteSettings.join_site_base(SKILL_COURSE_ITEM_EDIT_URI)
      end
    end
  end

  post '/bml_login' do
    error_no = CxbRank::BookmarkletAuthenticator.authenticate(params)
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
        if SiteSettings.rev_sunrise_mode?
          skill_set = SkillSet.new(settings.site_mode, session.user)
          skill_set.load!
          session.user.point = skill_set.total_point
          session.user.point_direct = false
          session.user.point_updated_at = Time.now
          session.user.save!
        end
        session.destroy
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end
end
