require 'cxbrank/const'
require 'cxbrank/pagemaker'
require 'cxbrank/user'

module CxbRank
	class UserAuthenticator < PageMaker
		def initialize(params, session)
			@params = params
			@session = session
		end

		def authenticate(user_id, password)
			return validate_params(user_id, password)
		end

		def to_html
			user_id = @params['user_id']
			password = @params['password']

			error_no = validate_params(user_id, password)
			if error_no != NO_ERROR
				return make_error_page(error_no, SITE_TOP_URI)
			end

			@session[:user] = User.find(user_id.to_i)

			return SKILL_LIST_EDIT_URI
		end

		private
		def validate_params(user_id, password)
			if user_id.empty?
				return ERROR_USERID_IS_UNINPUTED
			end
			if password.empty?
				return ERROR_PASSWORD1_IS_UNINPUTED
			end
			unless user_id.size == USER_ID_FIGURE
				return ERROR_USERID_OR_PASS_IS_WRONG
			end

			user = User.find(user_id.to_i)
			unless user
				return ERROR_USERID_OR_PASS_IS_WRONG
			end
			if user.password != Digest::MD5.hexdigest(password)
				return ERROR_USERID_OR_PASS_IS_WRONG
			end

			return NO_ERROR
		end
	end
end
