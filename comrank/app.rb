$LOAD_PATH << '../comrank/lib'

require 'active_support/all'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/multi_route'
require 'sinatra/json'
require 'sinatra/jsonp'
require 'sinatra/cross_origin'
require 'sinatra/default_charset'
require 'sinatra_more/markup_plugin'
require 'tilt/haml'
require 'rack/mobile-detect'
require 'rack/protection'
require 'cxbrank/site_settings'
require 'cxbrank/helpers'
require 'cxbrank/const'
require 'cxbrank/authenticate'
require 'cxbrank/master'
require 'cxbrank/master/music_set'
require 'cxbrank/user'
require 'cxbrank/skill'
require 'cxbrank/playdata/adversary_skill'
require 'cxbrank/master/app'
require 'cxbrank/playdata/app'

module CxbRank
  class AppBase < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::CrossOrigin
    register Sinatra::DefaultCharset
    register Sinatra::MultiRoute
    register SinatraMore::MarkupPlugin
    register CxbRank::Helpers
    register CxbRank::Master
    register CxbRank::PlayData

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
      Time.zone = 'Tokyo'
      SiteSettings.settings = settings
      settings.views = ['views',
        SiteSettings.join_comrank_path('views'), SiteSettings.join_comrank_path('views/application'),
      ]
      ActiveRecord::Base.configurations = YAML.load_file(DATABASE_FILE)
      ActiveRecord::Base.establish_connection(settings.environment)
      ActiveRecord::Base.default_timezone = :local
    end

    helpers Sinatra::Jsonp

    helpers do
      def page_last_modified(templates, data_mtime=nil, user=nil)
        if user.present?
          last_modified Time.now
        else
          mtimes = templates.map do |template|
            template.gsub!('#{comrank_path}', SiteSettings.join_comrank_path(''))
            Dir.glob(template).map do |file| File.mtime(file) end
          end.flatten
          mtimes << data_mtime
          last_modified mtimes.compact.max
        end
      end

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
            SiteSettings.pivot_date = date
          else
            date = nil
          end
        rescue ArgumentError
          date_error = true
        end
        if date_error
          haml :error, :layout => true,
            :locals => {:error_no => ERROR_DATE_IS_INVALID, :back_uri => SiteSettings.join_site_base(SITE_TOP_URI)}
        elsif date.present? and date < DATE_LOW_LIMITS[settings.site_mode]
          haml :error, :layout => true,
            :locals => {:error_no => ERROR_DATE_OUT_OF_RANGE, :back_uri => SiteSettings.join_site_base(SITE_TOP_URI)}
        else
          yield date
        end
      end

      def private_page(layout=true, &block)
        if session[:user_id].blank? or (user = User.find_by_id(session[:user_id])).nil?
          haml :error, :layout => layout,
            :locals => {:popup => !layout,
              :error_no => ERROR_SESSION_IS_DEAD, :back_uri => SiteSettings.join_site_base(SITE_TOP_URI)}
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
    end

    get '/googlee47e6c106efd57d5.html' do
      content_type :html
      send_file 'googlee47e6c106efd57d5.html'
    end

    get '/common/stylesheets/:file_name' do
      content_type :css
      send_file File.expand_path(params[:file_name], SiteSettings.join_comrank_path('stylesheets'))
    end

    get '/common/javascripts/:file_name' do
      content_type :js
      send_file File.expand_path(params[:file_name], SiteSettings.join_comrank_path('javascripts'))
    end

    get SITE_TOP_URI do
      data_mtime = [Master::Music.last_modified, Master::Event.last_modified].compact.max
      user = User.find_by_id(session[:user_id])
      page_last_modified PAGE_TEMPLATE_FILES[SITE_TOP_URI], data_mtime, user
      haml :index, :layout => true, :locals => {:user => user}
    end

    get USAGE_URI do
      page_last_modified PAGE_TEMPLATE_FILES[USAGE_URI]
      haml :usage, :layout => true
    end

    get USER_ADD_URI do
      settings.views << SiteSettings.join_comrank_path('views/user_edit')
      user = User.new
      if session["#{underscore(CxbRank::User)}_temp"].present?
        user.update_by_params!(session[underscore(CxbRank::User)])
      end
      session[:user_added] = false
      haml :user_add, :layout => true, :locals => {:user => user}
    end

    post USER_ADD_URI do
      settings.views << SiteSettings.join_comrank_path('views/user_edit_conf')
      user = User.create_by_params(params[underscore(CxbRank::User)])
      session["#{underscore(CxbRank::User)}_temp"] = Hash[params[underscore(CxbRank::User)]]
      unless user.valid?
        haml :error, :layout => true,
          :locals => {:errors => user.errors, :back_uri => SiteSettings.join_site_base(request.path_info)}
      else
        haml :user_add_conf, :layout => true, :locals => {:user => user}
      end
    end

    put USER_ADD_URI do
      if params[:y].present?
        settings.views << SiteSettings.join_comrank_path('views/user_edit')
        if session[:user_added]
          user = User.find_by_id(session[:user_id])
          haml :user_add_result, :layout => true, :locals => {:user => user}
        else
          begin
            user = User.create_by_params(session["#{underscore(CxbRank::User)}_temp"])
            user.save!
            session[:user_id] = user.id
            session[:user_added] = true
            session["#{underscore(CxbRank::User)}_temp"] = nil
            haml :user_add_result, :layout => true, :locals => {:user => user}
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => ERROR_DATABASE_SAVE_FAILED, :back_uri => SiteSettings.join_site_base(request.path_info)}
          end
        end
      else
        redirect SiteSettings.join_site_base(USER_ADD_URI)
      end
    end

    get USER_LIST_URI do
      settings.views << SiteSettings.join_comrank_path('views/user_list')
      users = User.find_actives
      data_mtime = User.last_modified
      if session[:user_id].nil?
        page_last_modified PAGE_TEMPLATE_FILES[USER_LIST_URI], data_mtime
      end
      haml :user_list, :layout => true, :locals => {:users => users}
    end

    post USER_LOGIN_URI do
      session[:user_id] = nil
      error_no = User.authenticate(params[:user_id], params[:password])
      if error_no != NO_ERROR
        haml :error, :layout => true,
          :locals => {:error_no => error_no, :back_uri => SiteSettings.join_site_base(SITE_TOP_URI)}
      else
        session[:user_id] = User.find_by_param_id(params[:user_id]).id
        redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
      end
    end

    get USER_LOGOUT_URI do
      session[:user_id] = nil
      redirect SiteSettings.join_site_base("#{SITE_TOP_URI}?#{Time.now.to_i}")
    end

    get USER_EDIT_URI do
      private_page do |user|
        settings.views << SiteSettings.join_comrank_path('views/user_edit')
        user.update_by_params!(session[underscore(CxbRank::User)])
        haml :user_edit, :layout => true, :locals => {:user => user}
      end
    end

    post USER_EDIT_URI do
      private_page do |user|
        settings.views << SiteSettings.join_comrank_path('views/user_edit_conf')
        user.update_by_params!(params[underscore(CxbRank::User)])
        session[underscore(CxbRank::User)] = Hash[params[underscore(CxbRank::User)]]
        unless user.valid?
          haml :error, :layout => true,
            :locals => {:errors => user.errors, :back_uri => SiteSettings.join_site_base(request.path_info)}
        else
          haml :user_edit_conf, :layout => true, :locals => {:user => user}
        end
      end
    end

    put USER_EDIT_URI do
      if params[:y].present?
        private_page do |user|
          settings.views << SiteSettings.join_comrank_path('views/user_edit')
          begin
            user.update_by_params!(session[underscore(CxbRank::User)])
            user.save!
            session[underscore(CxbRank::User)] = nil
            redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
          rescue
            haml :error, :layout => true,
              :locals => {:error_no => ERROR_DATABASE_SAVE_FAILED, :back_uri => SiteSettings.join_site_base(request.path_info)}
          end
        end
      else
        redirect SiteSettings.join_site_base(USER_EDIT_URI)
      end
    end

    get SCORE_RANK_URI do
      settings.views << SiteSettings.join_comrank_path('views/rank_score')
      music_set = Master::MusicSet.new
      music_set.load!
      data_mtime = music_set.last_modified
      page_last_modified PAGE_TEMPLATE_FILES[SCORE_RANK_URI], data_mtime
      haml :rank_score, :layout => true, :locals => {:music_set => music_set}
    end

    get "#{SCORE_RANK_DETAIL_URI}/:music_text_id?/?:diff?" do
      if params[:music_text_id].blank?
        haml :error, :layout => true, :locals => {:error_no => ERROR_MUSIC_IS_UNDECIDED}
      elsif (music = Music.find_by(:text_id => params[:music_text_id])).nil?
        haml :error, :layout => true, :locals => {:error_no => ERROR_MUSIC_NOT_EXIST}
      elsif params[:diff].blank?
        haml :error, :layout => true, :locals => {:error_no => ERROR_DIFF_IS_UNDECIDED}
      elsif (diff = SiteSettings.music_diffs.invert[params[:diff].upcase]).nil? or !music.exist?(diff)
        haml :error, :layout => true, :locals => {:error_no => ERROR_DIFF_NOT_EXIST}
      else
        settings.views << SiteSettings.join_comrank_path('views/rank_score_detail')
        fixed_title = "#{PAGE_TITLES[SCORE_RANK_DETAIL_URI]} [#{music.full_title} (#{SiteSettings.music_diffs[diff]})]"
        skills = Skill.get_rank_data(music, diff)
        haml :rank_score_detail, :layout => true, :locals => {
          :music => music, :diff => diff, :skills => skills, :fixed_title => fixed_title}
      end
    end

    post ADVERSARY_EDIT_URI do
      private_page(false) do |user|
        begin
          data = JSON.parse(request.body.read, {:symbolize_names => true})
          adversary = Adversary.where({:user_id => user.id, :adversary_id => data[:id].to_i}).first
          unless adversary
            adversary = Adversary.new
            adversary.user_id = user.id
            adversary.adversary_id = data[:id].to_i
          end
          if data[:status]
            adversary.save!
          else
            adversary.destroy
          end
          jsonx :result => 'success', :id => data[:id], :status => data[:status]
        rescue
          jsonx :result => 'failed'
        end
      end
    end

    get '/adversary/:music_text_id/:diff' do
      private_page(false) do |user|
        if params[:music_text_id].blank?
          haml :error, :layout => false, :locals => {:error_no => ERROR_MUSIC_IS_UNDECIDED}
        elsif (music = Master::Music.find_by(:text_id => params[:music_text_id])).nil?
          haml :error, :layout => false, :locals => {:error_no => ERROR_MUSIC_NOT_EXIST}
        elsif params[:diff].blank?
          haml :error, :layout => false, :locals => {:error_no => ERROR_DIFF_IS_UNDECIDED}
        elsif (diff = SiteSettings.music_diffs.invert[params[:diff].upcase]).nil? or !music.exist?(diff)
          haml :error, :layout => false, :locals => {:error_no => ERROR_DIFF_NOT_EXIST}
        else
          skills = PlayData::AdversarySkill.find_by_user_and_music_and_diff(user, music, diff)
          haml :adversary, :layout => false, :locals => {:music => music, :diff => diff, :skills => skills}
        end
      end
    end

    get ADVERSARY_FOLLOWINGS_URI do
      private_page(false) do |user|
        followings = Adversary.find_followings(user)
        haml :adversary_relations, :layout => false, :locals => {session_user: user, relations: followings, uri: ADVERSARY_FOLLOWINGS_URI}
      end
    end

    get ADVERSARY_FOLLOWERS_URI do
      private_page(false) do |user|
        followers = Adversary.find_followers(user)
        haml :adversary_relations, :layout => false, :locals => {session_user: user, relations: followers, uri: ADVERSARY_FOLLOWERS_URI}
      end
    end

    post '/api/authorize' do
      data = JSON.parse(request.body.read, {:symbolize_names => true})
      error_no = User.authenticate(data[:user_id], data[:password])
      jsonx error_no == NO_ERROR
    end

    get '/api/skills/:user_id' do
      user = User.find_by_param_id(params[:user_id])
      last_modified Skill.last_modified(user)
      skills = Skill.find_by_user(user, {:fill_empty => true, :limited => false}).to_a
      if SiteSettings.cxb_mode?
        skills.sort! do |a, b| a.music.number <=> b.music.number end
      else
        skills.sort! do |a, b| a.music.sort_key <=> b.music.sort_key end
      end
      skill_hashes = []
      skills.each do |skill|
        skill_hashes << skill.to_hash
      end
      jsonx skill_hashes
    end

    post '/api/edit' do
      data = JSON.parse(request.body.read, {:symbolize_names => true})
      error_no = User.authenticate(data[:user_id], data[:password])
      if error_no != NO_ERROR
        jsonx false
      else
        begin
          user = User.find_by_param_id(data[:user_id])
          music = Master::Music.find_by(:text_id => data[:text_id])
          skill = Skill.find_by_user_and_music(user, music)
          skill.user_id = user.id
          skill.music = music
          skill.comment = CGI.unescape(data[:body][:comment])
          MUSIC_DIFF_PREFIXES.keys.each do |diff|
            next unless data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym]
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_stat=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:stat])
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_point=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:point])
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_rate=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:rate])
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f=", SiteSettings.rev_mode?)
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_rank=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:rank])
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_combo=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:combo])
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_score=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:score])
            skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:gauge])
            if SiteSettings.cxb_mode?
              skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_locked=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:locked])
              skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_legacy=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:legacy])
            else
              skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_flawless=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:flawless])
              skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_super=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:super])
              skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_cool=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:cool])
              skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_maxcombo=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:maxcombo])
            end
          end
          skill.calc!
          skill.save!
          jsonx true
        rescue
          jsonx false
        end
      end
    end

    post '/api/edit_fix' do
      data = JSON.parse(request.body.read, {:symbolize_names => true})
      error_no = User.authenticate(data[:user_id], data[:password])
      if error_no != NO_ERROR
        jsonx false
      else
        begin
          user = User.find_by_param_id(data[:user_id])
          skill_set = SkillSet.new(user)
          skill_set.load!
          user.point = skill_set.total_point
          user.point_direct = false
          user.point_updated_at = Skill.last_modified(user)
          user.save!
          jsonx true
        rescue
          jsonx false
        end
      end
    end
  end
end
