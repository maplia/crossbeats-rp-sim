$LOAD_PATH << '../comrank/lib'
ENV['GEM_HOME'] = '/home/marines/local/gems/1.8'

require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'padrino-helpers'
require 'cxbrank/helpers'
require 'cxbrank/const'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/user'

module CxbRank
	class AppBase < Sinatra::Base
		register Sinatra::ConfigFile
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
			CxbRank::Music.set_mode(settings.site_mode)
		end

		get '/' do
			last_modified [File.mtime('views/index.haml'), File.mtime('views/index_news.haml')].max
			haml :index, :layout => true do
				haml :index_news
			end
		end

		get '/musics' do
			settings.views << '../comrank/views/music_list'
			music_set = CxbRank::MusicSet.load(settings.site_mode)
			last_modified music_set.last_modified
			haml :music_list, :layout => true, :locals => {:music_set => music_set}
		end

		get '/user_add' do
			settings.views << '../comrank/views/user_edit'
			session[:temp_user] ||= CxbRank::User.new
			haml :user_add, :layout => true
		end

		post '/user_add' do
			settings.views << '../comrank/views/user_edit_conf'
			session[:temp_user].attributes = params[underscore(CxbRank::User)]
			unless session[:temp_user].valid?
				haml :error, :layout => true,
					:locals => {:errors => session[:temp_user].errors, :back_uri => request.path_info}
			else
				haml :user_add_conf, :layout => true
			end
		end

		put '/user_add' do
			if params['y'].present?
				settings.views << '../comrank/views/user_edit'
				password_backup = session[:temp_user].password
				begin
					session[:temp_user].password = Digest::MD5.hexdigest(password_backup)
					session[:temp_user].password_confirmation = Digest::MD5.hexdigest(password_backup)
					session[:temp_user].save!
					session[:user] = session[:temp_user]
					session[:temp_user] = nil
					haml :user_add_result, :layout => true
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

		get '/user_list' do
			settings.views << '../comrank/views/user_list'
			last_modified CxbRank::User.last_modified
			users = CxbRank::User.find(:all, :conditions => 'display = 1 and point_updated_at is not null').sort
			haml :user_list, :layout => true, :locals => {:users => users}
		end

		get '/list' do
			settings.views << '../comrank/views/skill_list'
			last_modified = [CxbRank::Music.last_modified, CxbRank::Course.last_modified].max
			last_modified last_modified
			musics = CxbRank::Music.find(:all, :conditions => {:display => true}).sort
			courses = CxbRank::Course.find(:all, :conditions => {:display => true}).sort
			haml :music_list, :layout => true,
				:locals => {
					:last_modified => last_modified, :musics => musics, :courses => courses
				}
		end
	end
end
