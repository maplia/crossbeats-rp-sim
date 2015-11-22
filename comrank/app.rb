$LOAD_PATH << '../comrank/lib'
ENV['GEM_HOME'] = '/home/marines/local/gems/1.8'

require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/multi_route'
require 'sinatra/json'
require 'sinatra/jsonp'
require 'sinatra/cross_origin'
require 'sinatra/default_charset'
require 'tilt/haml'
require 'rack/mobile-detect'
require 'padrino-helpers'
require 'cxbrank/helpers'
require 'cxbrank/const'
require 'cxbrank/authenticate'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/user'
require 'cxbrank/skill'
require 'cxbrank/event'

module CxbRank
  class AppBase < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::CrossOrigin
    register Sinatra::DefaultCharset
    register Sinatra::MultiRoute
    register Padrino::Helpers
    register CxbRank::Helpers

    config_file File.expand_path(CxbRank::CONFIG_FILE, Dir.pwd)

    configure do
      use Rack::Session::Cookie,
        :key => settings.session_key, :secret => settings.secret,
        :expire_after => CxbRank::EXPIRE_MINUTES * 60
      set :public_dir, File.expand_path('public', Dir.pwd)
      set :method_override, true
      enable :cross_origin
      set :default_charset, 'utf-8'
      use Rack::MobileDetect
      mime_type :css, 'text/css'
      mime_type :js, 'text/javascript'
    end

    before do
      settings.views = ['views', '../comrank/views', '../comrank/views/application']
      ActiveRecord::Base.configurations = YAML.load_file(CxbRank::DATABASE_FILE)
      ActiveRecord::Base.establish_connection(settings.environment)
      CxbRank::Music.mode = settings.site_mode
      CxbRank::Skill.mode = settings.site_mode
    end

    helpers Sinatra::Jsonp

    helpers do
      def jsonx(data, callback=nil)
        cross_origin
        if callback
          jsonp data, callback
        else
          json data
        end
      end

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

      def skill_list_page(user, edit, skill_options={})
        settings.views << '../comrank/views/skill_list'
        skill_set = CxbRank::SkillSet.load(settings.site_mode, user, skill_options)
        last_modified skill_set.last_modified unless edit
        fixed_title = "#{user.name}さんの#{CxbRank::PAGE_TITLES[CxbRank::SKILL_LIST_VIEW_URI]}"
        haml :skill_list, :layout => true, :locals => {
          :user => user, :skill_set => skill_set,
          :edit => edit, :ignore_locked => skill_options[:ignore_locked], :fixed_title => fixed_title}
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

    get '/common/stylesheets/:file_name' do
      content_type :css
      send_file File.expand_path(params[:file_name], '../comrank/stylesheets')
    end

    get '/common/javascripts/:file_name' do
      content_type :js
      send_file File.expand_path(params[:file_name], '../comrank/javascripts')
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
      session[:temp_user].comment.gsub!(/\r\n/, "\n")
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
        if session[:user_id].present?
          user = CxbRank::User.find_by_id(session[:user_id])
          haml :user_add_result, :layout => true, :locals => {:user => user}
        else
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
        end
      else
        redirect CxbRank::USER_ADD_URI
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

    post CxbRank::USER_EDIT_URI do
      private_page do |user|
        settings.views << '../comrank/views/user_edit_conf'
        session[:temp_user].attributes = params[underscore(CxbRank::User)]
        if session[:temp_user].password.blank?
          session[:temp_user].password = user.password
        end
        if session[:temp_user].password_confirmation.blank?
          session[:temp_user].password_confirmation = user.password
        end
        unless session[:temp_user].valid?
          haml :error, :layout => true,
            :locals => {:errors => session[:temp_user].errors, :back_uri => request.path_info}
        else
          haml :user_edit_conf, :layout => true
        end
      end
    end

    put CxbRank::USER_EDIT_URI do
      if params['y'].present?
        settings.views << '../comrank/views/user_edit'
        password_backup = session[:temp_user].password
        begin
          if session[:temp_user].password_changed?
            session[:temp_user].password = Digest::MD5.hexdigest(password_backup)
            session[:temp_user].password_confirmation = Digest::MD5.hexdigest(password_backup)
          end
          session[:temp_user].save!
          session[:temp_user] = nil
          redirect CxbRank::SKILL_LIST_EDIT_URI
        rescue
          session[:temp_user].password = password_backup
          session[:temp_user].password_confirmation = password_backup
          haml :error, :layout => true,
            :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
        end
      else
        redirect CxbRank::USER_EDIT_URI
      end
    end

    get '/api/music/:param_id' do
      last_modified CxbRank::Music.last_modified
      music = CxbRank::Music.find_by_param_id(params[:param_id])
      jsonx (music ? music.to_hash : {}), params[:callback]
    end

    get '/api/musics' do
      last_modified CxbRank::Music.last_modified
      musics = CxbRank::Music.find(:all, :conditions => {:limited => false})
      music_hashes = []
      musics.sort.each do |music|
        music_hashes << music.to_hash
      end
      jsonx music_hashes, params[:callback]
    end

    get CxbRank::RANK_CALC_URI do
      last_modified CxbRank::Music.last_modified
      musics = CxbRank::Music.find(:all, :conditions => {:limited => false})
      music_hashes = []
      musics.sort.each do |music|
        music_hashes << music.to_hash
      end
      diffs = []
      music_diffs.keys.sort.each do |diff|
        diffs << CxbRank::MUSIC_DIFF_PREFIXES[diff]
      end
      haml :calc_rank, :layout => true, :locals => {:data => music_hashes, :diffs => diffs}
    end

    get CxbRank::RATE_CALC_URI do
      last_modified CxbRank::Music.last_modified
      musics = CxbRank::Music.find(:all, :conditions => {:limited => false})
      music_hashes = []
      musics.sort.each do |music|
        music_hashes << music.to_hash
      end
      haml :calc_rate, :layout => true, :locals => {:data => music_hashes, :diffs => music_diffs}
    end

    get CxbRank::MAX_SKILL_VIEW_URI do
      settings.views << '../comrank/views/skill_list'
      skill_set = CxbRank::SkillSet.max(settings.site_mode)
      last_modified skill_set.last_modified
      haml :skill_list, :layout => true, :locals => {
        :skill_set => skill_set, :edit => false, :ignore_locked => false}
    end

    get "#{CxbRank::EVENT_SHEET_URI}/:event_text_id", "#{CxbRank::EVENT_SHEET_URI}/:event_text_id/:section" do
      request.env['X_MOBILE_DEVICE'] = nil
      event = CxbRank::Event.find(:first,
        :conditions => {:text_id => params[:event_text_id], :section => (params[:section] || 0)})
      last_modified CxbRank::Music.last_modified
      haml :event_sheet, :layout => true, :locals => {:event => event}
    end
  end
end
