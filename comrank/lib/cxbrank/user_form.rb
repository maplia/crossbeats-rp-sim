require 'cxbrank/pagemaker'
require 'cxbrank/user'

module CxbRank
	class UserAddFormMaker < PageMaker
		def initialize(session)
			@session = session
			@template_html = 'user/user_add.html.erb'
		end

		def to_html
			@session[:temp_user] = User.new unless @session[:temp_user]
			user = @session[:temp_user]
			page_title = 'ユーザー情報登録'

			return ERB.new(read_template).result(binding)
		end
	end

	class UserAddCertifier < PageMaker
		def initialize(params, session)
			@params = params
			@session = session
			@template_html = 'user/user_add_conf.html.erb'
		end

		def to_html
			unless session_alive?
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end
			
			user = @session[:temp_user]
			user.name = @params['name']
			user.password = @params['password']
			user.password_confirmation = @params['password_confirmation']
			user.game_id = @params['game_id']
			user.game_id_display = (@params['game_id_display'] || 0)
			user.comment = @params['comment']
			@session[:temp_user] = user

			error_no = user.validate
			if error_no != NO_ERROR
				return make_error_page(error_no, ENV['PATH_INFO'])
			end
			page_title = 'ユーザー情報登録確認'

			return ERB.new(read_template).result(binding)
		end
	end

	class UserAddRegistrar < PageMaker
		def initialize(session)
			@session = session
			@template_html = 'user/user_add_result.html.erb'
		end

		def to_html
			unless session_alive?
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			user = @session[:temp_user]
			unless user.validate == NO_ERROR
				return make_error_page(ERROR_INVALID_ACCESS)
			end
			password_backup = user.password
			user.password = Digest::MD5.hexdigest(password_backup)
			user.password_confirmation = Digest::MD5.hexdigest(password_backup)

			begin
				user.save!
			rescue
				user.password = password_backup
				user.password_confirmation = password_backup
				return make_error_page(ERROR_DATABASE_SAVE_FAILED, ENV['PATH_INFO'])
			end
			@session[:user] = user
			@session[:temp_user] = nil
			page_title = 'ユーザー情報登録完了'

			return ERB.new(read_template).result(binding)
		end
	end

	class UserEditFormMaker < PageMaker
		def initialize(session)
			@session = session
			@template_html = 'user/user_edit.html.erb'
		end

		def to_html
			unless @session[:user]
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			unless @session[:temp_user]
				@session[:temp_user] = @session[:user]
				@session[:temp_user].password_confirmation = nil
			end
			user = @session[:temp_user]
			page_title = 'ユーザー情報編集'

			return ERB.new(read_template).result(binding)
		end
	end

	class UserEditCertifier < PageMaker
		def initialize(params, session)
			@params = params
			@session = session
			@template_html = 'user/user_edit_conf.html.erb'
		end

		def to_html
			unless session_alive?
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end
			
			user = @session[:temp_user]
			user.name = @params['name']
			unless @params['password'].empty?
				user.password = @params['password']
			end
			unless @params['password_confirmation'].empty?
				user.password_confirmation = @params['password_confirmation']
			end
			user.game_id = @params['game_id']
			user.game_id_display = (@params['game_id_display'] || 0)
			user.comment = @params['comment']
			@session[:temp_user] = user

			error_no = user.validate
			if error_no != NO_ERROR
				return make_error_page(error_no, ENV['PATH_INFO'])
			end
			page_title = 'ユーザー情報編集確認'

			return ERB.new(read_template).result(binding)
		end
	end

	class UserEditRegistrar < PageMaker
		def initialize(session)
			@session = session
		end

		def to_html
			unless session_alive?
				return make_error_page(ERROR_SESSION_IS_DEAD, SITE_TOP_URI)
			end

			user = @session[:temp_user]
			unless user.validate == NO_ERROR
				return make_error_page(ERROR_INVALID_ACCESS)
			end
			if user.password_changed?
				password_backup = user.password
				user.password = Digest::MD5.hexdigest(password_backup)
				user.password_confirmation = Digest::MD5.hexdigest(password_backup)
			end

			begin
				user.save!
			rescue
				return make_error_page(ERROR_DATABASE_SAVE_FAILED, ENV['PATH_INFO'])
			end
			@session[:user] = user
			@session[:temp_user] = nil

			return SKILL_LIST_EDIT_URI
		end
	end
end
