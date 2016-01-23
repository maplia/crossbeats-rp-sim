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

    config_file File.expand_path(CONFIG_FILE, Dir.pwd)

    configure do
      set :environment, settings.environment.to_sym
      set :sessions,
        :key => settings.session_key, :secret => settings.secret,
        :expire_after => EXPIRE_MINUTES * 60
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
      ActiveRecord::Base.configurations = YAML.load_file(DATABASE_FILE)
      ActiveRecord::Base.establish_connection(settings.environment)
      CxbRank::Music.mode = settings.site_mode
      CxbRank::Skill.mode = settings.site_mode
      CxbRank::User.mode = settings.site_mode
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

      def past_date_page(date_string, &block)
        begin
          if date_string.present?
            date = Date.strptime(date_string, '%Y%m%d')
          else
            date = nil
          end
        rescue ArgumentError
          date_error = true
        end
        if date_error
          haml :error, :layout => true,
            :locals => {:error_no => ERROR_DATE_IS_INVALID, :back_uri => SITE_TOP_URI}
        elsif date.present? and date < DATE_LOW_LIMITS[settings.site_mode]
          haml :error, :layout => true,
            :locals => {:error_no => ERROR_DATE_OUT_OF_RANGE, :back_uri => SITE_TOP_URI}
        else
          yield date
        end
      end

      def private_page(&block)
        if session[:user_id].blank? or (user = User.find_by_id(session[:user_id])).nil?
          haml :error, :layout => true,
            :locals => {:error_no => ERROR_SESSION_IS_DEAD, :back_uri => SITE_TOP_URI}
        else
          yield user
        end
      end

      def public_user_page(&block)
        if params[:user_id].blank?
          haml :error, :layout => true, :locals => {:error_no => ERROR_USERID_IS_UNINPUTED}
        elsif (user = User.find_by_param_id(params[:user_id])).nil?
          haml :error, :layout => true, :locals => {:error_no => ERROR_USERID_IS_UNREGISTERED}
        elsif !user.display
          haml :error, :layout => true, :locals => {:error_no => ERROR_USERID_IS_HIDDEN}
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
        if params[:music_text_id]
          session[:music_text_id] = params[:music_text_id]
        end
        if session[:music_text_id].blank?
          haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_MUSIC_IS_UNDECIDED}
        elsif (music = CxbRank::Music.find_by_param_id(session[:music_text_id])).nil?
          haml :error, :layout => true, :locals => {:error_no => CxbRank::ERROR_MUSIC_NOT_EXIST}
        else
          curr_skill = CxbRank::Skill.find_by_user_and_music(user, music)
          temp_skill = CxbRank::Skill.find_by_user_and_music(user, music)
          if params[underscore(CxbRank::Skill)]
            temp_skill.attributes = params[underscore(CxbRank::Skill)]
          end
          yield curr_skill, temp_skill
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

    get SITE_TOP_URI do
      last_modified [
        File.mtime('views/index.haml'), File.mtime('views/index_news.haml'),
        Music.last_modified, Event.last_modified
      ].compact.max
      haml :index, :layout => true do
        haml :index_news
      end
    end

    get USAGE_URI do
      last_modified File.mtime('views/usage.haml')
      haml :usage, :layout => true
    end

    get "#{MUSIC_LIST_VIEW_URI}/?:date_string?" do
      settings.views << '../comrank/views/music_list'
      past_date_page(params[:date_string]) do |date|
        music_set = MusicSet.new(settings.site_mode, date)
        last_modified music_set.last_modified
        music_set.load!
        if date.present?
          fixed_title = "#{PAGE_TITLES[MUSIC_LIST_VIEW_URI]} [#{date.strftime('%Y-%m-%d')}]"
        else
          fixed_title = PAGE_TITLES[MUSIC_LIST_VIEW_URI]
        end
        haml :music_list, :layout => true,
          :locals => {:music_set => music_set, :date => date, :fixed_title => fixed_title}
      end
    end

    get '/api/music/:music_text_id' do
      last_modified Music.last_modified(params[:music_text_id])
      music = Music.find_by_param_id(params[:music_text_id])
      jsonx((music ? music.to_hash : {}), params[:callback])
    end

    get '/api/musics' do
      last_modified Music.last_modified
      music_hashes = Music.find_actives.map! do |music| music.to_hash end
      jsonx music_hashes, params[:callback]
    end

    get "#{MAX_SKILL_VIEW_URI}/?:date_string?" do
      settings.views << '../comrank/views/skill_list'
      past_date_page(params[:date_string]) do |date|
        skill_set = SkillMaxSet.new(settings.site_mode, date)
        last_modified skill_set.last_modified
        skill_set.load!
        if date.present?
          fixed_title = "#{PAGE_TITLES[MAX_SKILL_VIEW_URI]} [#{date.strftime('%Y-%m-%d')}]"
        else
          fixed_title = PAGE_TITLES[MAX_SKILL_VIEW_URI]
        end
        haml :skill_list, :layout => true, :locals => {
          :skill_set => skill_set, :edit => false,
          :date => date, :ignore_locked => false, :fixed_title => fixed_title}
      end
    end

    get USER_ADD_URI do
      settings.views << '../comrank/views/user_edit'
      user = User.new
      user = User.create_by_params(session[underscore(CxbRank::User)])
      session[:user_added] = false
      haml :user_add, :layout => true, :locals => {:user => user}
    end

    post USER_ADD_URI do
      settings.views << '../comrank/views/user_edit_conf'
      user = User.create_by_params(params[underscore(CxbRank::User)])
      session[underscore(CxbRank::User)] = Hash[params[underscore(CxbRank::User)]]
      unless user.valid?
        haml :error, :layout => true,
          :locals => {:errors => user.errors, :back_uri => request.path_info}
      else
        haml :user_add_conf, :layout => true, :locals => {:user => user}
      end
    end

    put USER_ADD_URI do
      if params[:y].present?
        settings.views << '../comrank/views/user_edit'
        if session[:user_added]
          user = CxbRank::User.find_by_id(session[:user_id])
          haml :user_add_result, :layout => true, :locals => {:user => user}
        else
          begin
            user = User.create_by_params(session[underscore(CxbRank::User)])
            user.save!
            session[:user_id] = user.id
            session[:user_added] = true
            session[underscore(CxbRank::User)] = nil
            haml :user_add_result, :layout => true, :locals => {:user => user}
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
          end
        end
      else
        redirect USER_ADD_URI
      end
    end

    get USER_LIST_URI do
      settings.views << '../comrank/views/user_list'
      last_modified User.last_modified
      users = User.find_actives
      haml :user_list, :layout => true, :locals => {:users => users}
    end

    post USER_LOGIN_URI do
      session[:user_id] = nil
      error_no = Authenticator.authenticate(params)
      if error_no != NO_ERROR
        haml :error, :layout => true,
          :locals => {:error_no => error_no, :back_uri => SITE_TOP_URI}
      else
        session[:user_id] = User.find_by_param_id(params[:user_id]).id
        redirect SKILL_LIST_EDIT_URI
      end
    end

    get USER_LOGOUT_URI do
      session[:user_id] = nil
      redirect SITE_TOP_URI
    end

    get USER_EDIT_URI do
      private_page do |user|
        settings.views << '../comrank/views/user_edit'
        user.update_by_params!(session[underscore(CxbRank::User)])
        haml :user_edit, :layout => true, :locals => {:user => user}
      end
    end

    post USER_EDIT_URI do
      private_page do |user|
        settings.views << '../comrank/views/user_edit_conf'
        user.update_by_params!(params[underscore(CxbRank::User)])
        session[underscore(CxbRank::User)] = Hash[params[underscore(CxbRank::User)]]
        unless user.valid?
          haml :error, :layout => true,
            :locals => {:errors => user.errors, :back_uri => request.path_info}
        else
          haml :user_edit_conf, :layout => true, :locals => {:user => user}
        end
      end
    end

    put USER_EDIT_URI do
      if params[:y].present?
        private_page do |user|
          settings.views << '../comrank/views/user_edit'
          begin
            user.update_by_params!(session[underscore(CxbRank::User)])
            user.save!
            session[underscore(CxbRank::User)] = nil
            redirect SKILL_LIST_EDIT_URI
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
          end
        end
      else
        redirect USER_EDIT_URI
      end
    end

    get CxbRank::SKILL_LIST_EDIT_URI do
      private_page do |user|
        skill_list_page user, true, :fill_empty => true
      end
    end

    get "#{CxbRank::SKILL_LIST_VIEW_URI}/?:user_id?" do
      public_user_page do |user|
        skill_list_page user, false
      end
    end

    get "#{CxbRank::SKILL_LIST_VIEW_IGLOCK_URI}/?:user_id?" do
      public_user_page do |user|
        skill_list_page user, false, :ignore_locked => true
      end
    end

    get "#{CxbRank::CLEAR_LIST_VIEW_URI}/?:user_id?" do
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

    get "#{CxbRank::SKILL_ITEM_EDIT_URI}/?:music_text_id?" do
      private_page do |user|
        music_skill_edit_page(user) do |curr_skill, temp_skill|
          settings.views << '../comrank/views/music_skill_edit'
          fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
          haml :music_skill_edit, :layout => true, :locals => {
            :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title}
        end
      end
    end

    post CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        music_skill_edit_page(user) do |curr_skill, temp_skill|
          settings.views << '../comrank/views/music_skill_edit'
          unless temp_skill.valid?
            haml :error, :layout => true,
              :locals => {:errors => temp_skill.errors, :back_uri => request.path_info}
          else
            temp_skill.calc!
            method = (params[:update].present? ? 'put' : 'delete')
            fixed_title = "#{CxbRank::PAGE_TITLES[CxbRank::SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
            haml :music_skill_edit_conf, :layout => true, :locals => {
              :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title, :method => method}
          end
        end
      end
    end

    put CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        if params[:y].present?
          music_skill_edit_page(user) do |curr_skill, temp_skill|
            begin
              temp_skill.calc!
              temp_skill.save!
              user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
              user.point_direct = false
              user.point_updated_at = Time.now
              user.save!
              session[:music_text_id] = nil
              redirect CxbRank::SKILL_LIST_EDIT_URI
            rescue
               haml :error, :layout => true,
                 :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
            end
          end
        else
          redirect CxbRank::SKILL_ITEM_EDIT_URI
        end
      end
    end

    delete CxbRank::SKILL_ITEM_EDIT_URI do
      private_page do |user|
        if params['y'].present?
          music_skill_edit_page(user) do |curr_skill, temp_skill|
            begin
              temp_skill.destroy
              user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
              user.point_direct = false
              user.point_updated_at = Time.now
              user.save!
              session[:music_text_id] = nil
              redirect CxbRank::SKILL_LIST_EDIT_URI
            rescue
              haml :error, :layout => true,
                :locals => {:error_no => CxbRank::ERROR_DATABASE_SAVE_FAILED, :back_uri => request.path_info}
            end
          end
        else
          redirect CxbRank::SKILL_ITEM_EDIT_URI
        end
      end
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

    get EVENT_SHEET_URI do
      settings.views << '../comrank/views/event_list'
      last_modified Event.last_modified
      events = Event.where(true).sort
      fixed_title = "#{PAGE_TITLES[EVENT_SHEET_URI]}一覧"
      haml :event_list, :layout => true, :locals => {:events => events, :fixed_title => fixed_title}
    end

    get "#{EVENT_SHEET_URI}/:event_text_id?/?:section?" do
      if params[:event_text_id].blank?
        haml :error, :layout => true, :locals => {:error_no => ERROR_EVENT_ID_IS_UNDECIDED}
      elsif !(events = Event.where(:text_id => params[:event_text_id])).exists?
        haml :error, :layout => true, :locals => {:error_no => ERROR_EVENT_ID_NOT_EXIST}
      elsif (event = events.where(:section => (params[:section] || 0)).first).nil?
        haml :error, :layout => true, :locals => {:error_no => ERROR_EVENT_SECTION_NOT_EXIST}
      else
        last_modified event.updated_at
        request.env['X_MOBILE_DEVICE'] = nil
        fixed_title = "#{PAGE_TITLES[EVENT_SHEET_URI]} [#{event.title}]"
        haml :event_sheet, :layout => true, :locals => {:event => event, :fixed_title => fixed_title}
      end
    end
  end
end
