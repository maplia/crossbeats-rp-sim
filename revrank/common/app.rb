$LOAD_PATH << '../../comrank/lib'
require '../../comrank/app'
require 'json'
require 'cxbrank/const'
require 'cxbrank/master/music'
require 'cxbrank/master/course'
require 'cxbrank/playdata/music_skill'
require 'cxbrank/playdata/course_skill'
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
      elsif (course = Master::Course.find_by(:text_id => session[:course_text_id])).nil?
        haml :error, :layout => true, :locals => {:error_no => ERROR_COURSE_NOT_EXIST}
      else
        curr_skill = PlayData::CourseSkill.find_by_user_and_course(user, course)
        temp_skill = PlayData::CourseSkill.find_by_user_and_course(user, course)
        if params[:course_text_id]
          session[underscore(CxbRank::PlayData::CourseSkill)] = nil
        end
        if session[underscore(CxbRank::PlayData::CourseSkill)].present?
          temp_skill.update_by_params!(session[underscore(CxbRank::PlayData::CourseSkill)])
        end
        yield curr_skill, temp_skill
      end
    end

    def valid_referrer?
      return (request.referrer || '').include?(settings.mydata_host)
    end

    def bookmarklet_session(&block)
      if !valid_referrer?
        jsonx :status => 401, :message => 'MY PAGEからのアクセスではありません'
      elsif (data = JSON.parse(request.body.read, {:symbolize_names => true}))[:key].blank?
        jsonx :status => 401, :message => 'セッションキーが指定されていません'
      elsif (session = BookmarkletSession.find_by(:key => data[:key])).nil?
        jsonx :status => 401, :message => 'セッションキーが間違っています'
      else
        begin
          session.edit_count += 1
          session.save!
          yield session, data
        rescue
          jsonx :status => 400, :message => $!.message
        end
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
    session[underscore(CxbRank::PlayData::CourseSkill)] = Hash[params[underscore(CxbRank::PlayData::CourseSkill)]]
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
            skill_set = SkillSet.new(user)
            skill_set.calc!
            user.point = skill_set.total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:course_text_id] = nil
            session[underscore(CxbRank::PlayData::CourseSkill)] = nil
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
            skill_set = SkillSet.new(user)
            skill_set.calc!
            user.point = skill_set.total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:course_text_id] = nil
            session[underscore(CxbRank::PlayData::CourseSkill)] = nil
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
    if !valid_referrer?
      jsonx :status => 401, :message => 'MY PAGEからのアクセスではありません'
    elsif (error_no = CxbRank::BookmarkletAuthenticator.authenticate(params)) != CxbRank::NO_ERROR
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
          item = Master::Music.create_by_request(data[:body])
          item.save!
        when 'course'
          item = Master::Course.create_by_request(data[:body])
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
          if (music = Master::Music.find_by(:lookup_key => data[:lookup_key])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          elsif (skill = PlayData::MusicSkill.create_by_request(session.user, music, data[:body])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          else
            skill.save!
          end
        when 'course'
          if (course = Master::Course.find_by(:lookup_key => data[:lookup_key])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          elsif (skill = PlayData::CourseSkill.create_by_request(session.user, course, data[:body])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          else
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
