$LOAD_PATH << '../comrank/lib'
ENV['GEM_HOME'] = '/home/marines/local/gems/1.8'

require 'rubygems'
require 'json'
require 'sinatra'
require 'sinatra_more'
require 'sinatra/config_file'
require 'sinatra/json'
require 'sinatra/jsonp'
require 'sinatra/cross_origin'
require 'sinatra/default_charset'
require 'rack/mobile-detect'
require 'active_record'
require 'cxbrank/const'
require 'cxbrank/authenticate'
require 'cxbrank/skill_view'
require 'cxbrank/skill_form'
require 'cxbrank/skill_chart'
require 'cxbrank/user_view'
require 'cxbrank/user_form'
require 'cxbrank/calc'
require 'cxbrank/bookmarklet'
require 'cxbrank/user'

def to_json(data, callback=nil)
	cross_origin
	if callback
		return jsonp(data, callback)
	else
		return json(data)
	end
end

def log_bml_error(json, key)
	log = CxbRank::JsonLog.new
	log.json = json
	log.user_id = CxbRank::BookmarkletSession.find(:first, :conditions => {:key => key}).user.id
	log.message = $!.message
	log.save!
	return to_json({:status => 500, :message => $!.message})
end

config_file CxbRank::CONFIGURATION_FILE

configure do
	$config = CxbRank::SiteConfig.new
	use Rack::Session::Cookie,
		:path => '/',
		:key => "#{$config.session_key}.session",
		:expire_after => CxbRank::EXPIRE_MINUTES * 60,
		:secret => $config.secret
	enable :cross_origin
	use Rack::MobileDetect
	register Sinatra::DefaultCharset
	set :default_charset, 'utf-8'
	set :views, ['views', '../comrank/views', '../comrank/views/application']
	register Sinatra::
end

helpers do
	def site_top?
		return request.path_info.blank? || (request.path_info == CxbRank::SITE_TOP_URI)
	end

	def page_title(path_info=request.path_info)
		if path_info.blank? or path_info == CxbRank::SITE_TOP_URI
			return (mobile? ? '' : settings.site_name) << ' ' << CxbRank::PAGE_TITLES[CxbRank::SITE_TOP_URI]
		else
			return CxbRank::PAGE_TITLES[path_info]
		end
	end

	def mobile?
		return request.env['X_MOBILE_DEVICE'].present?
	end

	def cxb_mode?
		return settings.site_mode == CxbRank::MODE_CXB
	end

	def rev_mode?
		return settings.site_mode == CxbRank::MODE_REV
	end

	def music_diffs
		return CxbRank::MUSIC_DIFFS[settings.site_mode]
	end

	def music_types
		return CxbRank::MUSIC_TYPES[settings.site_mode]
	end

	def link_to(uri, text=url)
		return %Q(<a href="#{uri}">#{text}</a>)
	end

	def find_template(views, name, engine, &block)
		Array(views).each do |v|
			super(v, name, engine, &block)
		end
	end
end

before do
	ActiveRecord::Base.configurations = YAML.load_file(CxbRank::DATABASE_FILE)
	ActiveRecord::Base.establish_connection(settings.environment)
	$mobile = request.env['X_MOBILE_DEVICE'].present?
end

get '/' do
	last_modified [File.mtime('views/index.erb'), File.mtime('views/index_news.erb')].max
	erb :index, :layout => true do
		erb :index_news
	end
end

get '/musics' do
	settings.views << '../comrank/views/music_list'
	last_modified = [CxbRank::Music.last_modified, CxbRank::Course.last_modified].max
	last_modified last_modified
	musics = CxbRank::Music.find(:all, :conditions => {:display => true}).sort
	courses = CxbRank::Course.find(:all, :conditions => {:display => true}).sort
	erb :music_list, :layout => true,
		:locals => {
			:last_modified => last_modified, :musics => musics, :courses => courses
		}
end

get '/user_add' do
	settings.views << '../comrank/views/user_edit'
	session[:temp_user] ||= CxbRank::User.new
	erb :user_add, :layout => true
end

post '/user_add' do
	settings.views << '../comrank/views/user_edit_conf'
	
	erb :user_add_conf, :layout => true
end

put '/user_add' do
	if params['n'].present?
		settings.views << '../comrank/views/user_edit'
		erb :user_add, :layout => true
	else
		settings.views << '../comrank/views/user_add_result'
		erb :user_add_result, :layout => true
	end
end

post '/login' do
	session[:user] = nil
	session[:temp_user] = nil
	maker = CxbRank::UserAuthenticator.new(params, session)
	result = maker.to_html
	if result =~ /html/
		result
	else
		redirect result
	end
end

get '/logout' do
	session[:user] = nil
	redirect CxbRank::SITE_TOP_URI
end

get '/list' do
	maker = CxbRank::SkillEditListMaker.new(session)
	maker.to_html
end

get '/view/:user_id' do
	maker = CxbRank::SkillViewListMaker.new(params)
	last_modified maker.last_modified
	maker.to_html
end

get '/iglock/:user_id' do
	maker = CxbRank::SkillIgLockListMaker.new(params)
	last_modified maker.last_modified
	maker.to_html
end

get '/chart/:user_id' do
	maker = CxbRank::SkillChartMaker.new(params)
	last_modified maker.last_modified
	maker.to_html
end

get '/edit/:text_id' do
	session[:music] = nil
	session[:temp_skill] = nil
	maker = CxbRank::SkillEditFormMaker.new(params, session)
	maker.to_html
end

post '/edit' do
	if params['y'].nil? and params['n'].nil?
		maker = CxbRank::SkillEditCertifier.new(params, session)
		maker.to_html
	elsif params['n']
		maker = CxbRank::SkillEditFormMaker.new(nil, session)
		maker.to_html
	else
		maker = CxbRank::SkillEditRegistrar.new(session)
		result = maker.to_html
		if result =~ /html/
			result
		else
			redirect result
		end
	end
end

get '/edit_course/:text_id' do
	session[:course] = nil
	session[:temp_skill] = nil
	maker = CxbRank::CourseSkillEditFormMaker.new(params, session)
	maker.to_html
end

post '/edit_course' do
	if params['y'].nil? and params['n'].nil?
		maker = CxbRank::CourseSkillEditCertifier.new(params, session)
		maker.to_html
	elsif params['n']
		maker = CxbRank::CourseSkillEditFormMaker.new(nil, session)
		maker.to_html
	else
		maker = CxbRank::CourseSkillEditRegistrar.new(session)
		result = maker.to_html
		if result =~ /html/
			result
		else
			redirect result
		end
	end
end

get '/user_edit' do
	maker = CxbRank::UserEditFormMaker.new(session)
	maker.to_html
end

post '/user_edit' do
	if params['y'].nil? and params['n'].nil?
		maker = CxbRank::UserEditCertifier.new(params, session)
		maker.to_html
	elsif params['n']
		maker = CxbRank::UserEditFormMaker.new(session)
		maker.to_html
	else
		maker = CxbRank::UserEditRegistrar.new(session)
		result = maker.to_html
		if result =~ /html/
			result
		else
			redirect result
		end
	end
end

get '/user_list' do
	maker = CxbRank::UserListMaker.new(session)
	last_modified maker.last_modified
	maker.to_html
end

get '/api/user/:param_id' do
	user = CxbRank::User.find_by_param_id(@params[:param_id])
	to_json((user ? user.to_hash : {}), params[:callback])
end

get '/api/music/:param_id' do
	music = CxbRank::Music.find_by_param_id(@params[:param_id])
	to_json((music ? music.to_hash : {}), params[:callback])
end

get '/api/musics' do
	musics = CxbRank::Music.find(:all, :conditions => {:limited => 0})
	hashes = []
	musics.sort.each do |music|
		hashes << music.to_hash
	end
	to_json(hashes, params[:callback])
end

get '/rankcalc' do
	maker = CxbRank::RankCalculatorMaker.new
	last_modified maker.last_modified
	maker.to_html
end

post '/bml_login' do
	executor = CxbRank::BookmarkletAuthenticator.new(params)
	to_json(executor.execute)
end

post '/bml_update_master' do
	begin
		json = request.body.read
		data = JSON.parse(json, {:symbolize_names => true})
		executor = CxbRank::BookmarkletMasterUpdater.new(data)
		to_json(executor.execute)
	rescue
		log_bml_error(json, data[:key])
	end
end

post '/bml_edit' do
	begin
		json = request.body.read
		data = JSON.parse(json, {:symbolize_names => true})
		executor = CxbRank::BookmarkletSkillEditor.new(data)
		to_json(executor.execute)
	rescue
		log_bml_error(json, data[:key])
	end
end

post '/bml_point' do
	begin
		json = request.body.read
		data = JSON.parse(json, {:symbolize_names => true})
		executor = CxbRank::BookmarkletPointEditor.new(data)
		to_json(executor.execute)
	rescue
		log_bml_error(json, data[:key])
	end
end

post '/bml_logout' do
	executor = CxbRank::BookmarkletSessionTerminator.new(params)
	to_json(executor.execute)
end
