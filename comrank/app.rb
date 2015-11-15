$LOAD_PATH << '../comrank/lib'
ENV['GEM_HOME'] = '/home/marines/local/gems/1.8'

require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/multi_route'
require 'padrino-helpers'
require 'cxbrank/helpers'
require 'cxbrank/const'
require 'cxbrank/authenticate'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/user'
require 'cxbrank/skill'

module CxbRank
  class AppBase < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::MultiRoute
    register Padrino::Helpers
    register CxbRank::Helpers

    config_file File.expand_path(CxbRank::CONFIG_FILE, Dir.pwd)

    configure do
      use Rack::Session::Cookie,
        :key => settings.session_key, :secret => settings.secret,
        :expire_after => CxbRank::EXPIRE_MINUTES * 60
      set :views, ['views', '../comrank/views', '../comrank/views/application']
      set :method_override, true
    end

    before do
      ActiveRecord::Base.configurations = YAML.load_file(CxbRank::DATABASE_FILE)
      ActiveRecord::Base.establish_connection(settings.environment)
      CxbRank::Music.mode = settings.site_mode
      CxbRank::Skill.mode = settings.site_mode
    end

    helpers do
      def private_page(&block)
        if session[:user_id].blank? or (user = CxbRank::User.find_by_id(session[:user_id])).nil?
          haml :error, :layout => true,
            :locals => {:error_no => CxbRank::ERROR_SESSION_IS_DEAD, :back_uri => CxbRank::SITE_TOP_URI}
        else
          yield user
        end
      end

      def public_user_page(&block)
        if params[:user_id].blank?
          haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_USERID_IS_UNINPUTED}
        elsif (user = CxbRank::User.find_by_param_id(params[:user_id])).nil?
          haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_USERID_IS_UNREGISTERED}
        else
          yield user
        end
      end

      def skill_list_page(user, edit, options={})
        settings.views << '../comrank/views/skill_list'
        skill_set = CxbRank::SkillSet.load(settings.site_mode, user, options)
        last_modified skill_set.last_modified unless edit
        fixed_title = "#{user.name}さんの#{CxbRank::PAGE_TITLES[CxbRank::SKILL_LIST_VIEW_URI]}"
        haml :skill_list, :layout => true, :locals => {
          :user => user, :skill_set => skill_set,
          :edit => edit, :ignore_locked => options[:ignore_locked], :fixed_title => fixed_title}
      end

      def music_skill_edit_page(user, &block)
        music_text_id = (session[:music_text_id] || params[:music_text_id])
        if music_text_id.blank?
          haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_MUSIC_IS_UNDECIDED}
        elsif (music = CxbRank::Music.find_by_param_id(music_text_id)).nil?
          haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_MUSIC_NOT_EXIST}
        else
          curr_skill = CxbRank::Skill.find_by_user_and_music(user, music)
          yield curr_skill
        end
      end
    end

    get CxbRank::SITE_TOP_URI do
      last_modified [File.mtime('views/index.haml'), File.mtime('views/index_news.haml')].max
      haml :index, :layout => true do
        haml :index_news
      end
    end

    get CxbRank::MUSIC_LIST_VIEW_URI do
      settings.views << '../comrank/views/music_list'
      music_set = CxbRank::MusicSet.load(settings.site_mode)
      last_modified music_set.last_modified
      haml :music_list, :layout => true, :locals => {:music_set => music_set}
    end

    get CxbRank::USER_ADD_URI do
      settings.views << '../comrank/views/user_edit'
      session[:temp_user] ||= CxbRank::User.new
      haml :user_add, :layout => true
    end

    post CxbRank::USER_ADD_URI do
      settings.views << '../comrank/views/user_edit_conf'
      session[:temp_user].attributes = params[underscore(CxbRank::User)]
      unless session[:temp_user].valid?
        haml :error, :layout => true,
          :locals => {:errors => session[:temp_user].errors, :back_uri => request.path_info}
      else
        haml :user_add_conf, :layout => true
      end
    end

    put CxbRank::USER_ADD_URI do
      if params['y'].present?
        settings.views << '../comrank/views/user_edit'
        password_backup = session[:temp_user].password
        begin
          session[:temp_user].password = Digest::MD5.hexdigest(password_backup)
          session[:temp_user].password_confirmation = Digest::MD5.hexdigest(password_backup)
          session[:temp_user].save!
          user = session[:temp_user]
          session[:user_id] = user.id
          session[:temp_user] = nil
          haml :user_add_result, :layout => true, :locals => {:user => user}
        rescue
          session[:temp_user].password = password_backup
          session[:temp_user].password_confirmation = password_backup
          haml :error, :layout => true,
            :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
        end
      else
        settings.views << '../comrank/views/user_edit'
        haml :user_add, :layout => true
      end
    end

    get CxbRank::USER_LIST_URI do
      settings.views << '../comrank/views/user_list'
      last_modified CxbRank::User.last_modified
      users = CxbRank::User.find(:all, :conditions => 'display = 1 and point_updated_at is not null').sort
      haml :user_list, :layout => true, :locals => {:users => users}
    end

    post CxbRank::USER_LOGIN_URI do
      session[:temp_user] = nil
      error_no = CxbRank::Authenticator.authenticate(params)
      if error_no != CxbRank::NO_ERROR
        haml :error, :layout => true,
          :locals => {:error_no => error_no, :back_uri => CxbRank::SITE_TOP_URI}
      else
        session[:user_id] = CxbRank::User.find_by_param_id(params[:user_id]).id
        redirect CxbRank::SKILL_LIST_EDIT_URI
      end
    end

    get CxbRank::USER_LOGOUT_URI do
      session[:user_id] = nil
      redirect CxbRank::SITE_TOP_URI
    end

    get CxbRank::SKILL_LIST_EDIT_URI do
      private_page do |user|
        skill_list_page user, true, :fill_empty => true
      end
    end

    get CxbRank::SKILL_LIST_VIEW_URI, "#{CxbRank::SKILL_LIST_VIEW_URI}/:user_id" do
      public_user_page do |user|
        skill_list_page user, false
      end
    end

    get CxbRank::SKILL_LIST_VIEW_IGLOCK_URI, "#{CxbRank::SKILL_LIST_VIEW_IGLOCK_URI}/:user_id" do
      public_user_page do |user|
        skill_list_page user, false, :ignore_locked => true
      end
    end

    get CxbRank::CLEAR_LIST_VIEW_URI, "#{CxbRank::CLEAR_LIST_VIEW_URI}/:user_id" do
      public_user_page do |user|
        settings.views << '../comrank/views/skill_chart'
        settings.views << '../comrank/views/skill_list'
        skill_chart = CxbRank::SkillChart.load(settings.site_mode, user)
        last_modified skill_chart.last_modified
        fixed_title = "#{user.name}さんの#{CxbRank::PAGE_TITLES[CxbRank::CLEAR_LIST_VIEW_URI]}"
        haml :skill_chart, :layout => true, :locals => {
          :user => user, :skill_chart => skill_chart, :fixed_title => fixed_title}
      end
    end

    get "#{CxbRank::SKILL_ITEM_EDIT_URI}/:music_text_id" do
      private_page do |user|
        music_skill_edit_page(user) do |curr_skill|
          settings.views << '../comrank/views/music_skill_edit'
          session[:music_text_id] = params[:music_text_id]
          session[:temp_skill] = curr_skill.dup
          fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
          haml :music_skill_edit, :layout => true, :locals => {
            :curr_skill => curr_skill, :temp_skill => session[:temp_skill], :fixed_title => fixed_title}
        end
      end
    end

    get CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        music_skill_edit_page(user) do |curr_skill|
          settings.views << '../comrank/views/music_skill_edit'
          fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
          haml :music_skill_edit, :layout => true, :locals => {
            :curr_skill => curr_skill, :temp_skill => session[:temp_skill], :fixed_title => fixed_title}
        end
      end
    end

    post CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        music_skill_edit_page(user) do |curr_skill|
          settings.views << '../comrank/views/music_skill_edit'
          session[:temp_skill].attributes = params[underscore(CxbRank::Skill)]
          unless session[:temp_skill].valid?
            haml :error, :layout => true,
              :locals => {:errors => session[:temp_skill].errors, :back_uri => request.path_info}
          else
            session[:temp_skill].calc!
            method = (params[:update].present? ? 'put' : 'delete')
            fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
            haml :music_skill_edit_conf, :layout => true, :locals => {
              :curr_skill => curr_skill, :temp_skill => session[:temp_skill],
              :fixed_title => fixed_title, :method => method}
          end
        end
      end
    end

    put CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        if params['y'].present?
#          begin
            session[:temp_skill].save!
            user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:music_text_id] = nil
            redirect CxbRank::SKILL_LIST_EDIT_URI
#          rescue
#            haml :error, :layout => true,
#              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
#          end
        else
          redirect CxbRank::SKILL_ITEM_EDIT_URI
        end
      end
    end

    delete CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        if params['y'].present?
#          begin
            session[:temp_skill].destroy
            user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
            user.point_direct = false
            user.point_updated_at = Time.now
            user.save!
            session[:music_text_id] = nil
            redirect CxbRank::SKILL_LIST_EDIT_URI
#          rescue
#            haml :error, :layout => true,
#              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
#          end
        else
          redirect CxbRank::SKILL_ITEM_EDIT_URI
        end
      end
    end

    get CxbRank::USER_EDIT_URI do
      private_page do |user|
        settings.views << '../comrank/views/user_edit'
        session[:temp_user] ||= user
        haml :user_edit, :layout => true
      end
    end

    post CxbRank::USER_ADD_URI do
      settings.views << '../comrank/views/user_edit_conf'
      session[:temp_user].attributes = params[underscore(CxbRank::User)]
      unless session[:temp_user].valid?
        haml :error, :layout => true,
          :locals => {:errors => session[:temp_user].errors, :back_uri => request.path_info}
      else
        haml :user_add_conf, :layout => true
      end
    end

    put CxbRank::USER_ADD_URI do
      if params['y'].present?
        settings.views << '../comrank/views/user_edit'
        password_backup = session[:temp_user].password
        begin
          session[:temp_user].password = Digest::MD5.hexdigest(password_backup)
          session[:temp_user].password_confirmation = Digest::MD5.hexdigest(password_backup)
          session[:temp_user].save!
          user = session[:temp_user]
          session[:user_id] = user.id
          session[:temp_user] = nil
          haml :user_add_result, :layout => true, :locals => {:user => user}
        rescue
          session[:temp_user].password = password_backup
          session[:temp_user].password_confirmation = password_backup
          haml :error, :layout => true,
            :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
        end
      else
        settings.views << '../comrank/views/user_edit'
        haml :user_add, :layout => true
      end
    end
  end
end
