require 'cxbrank/const'
require 'cxbrank/user'

module CxbRank
  class Authenticator
    def self.authenticate(params)
      unless params[:user_id].present?
        return ERROR_USERID_IS_UNINPUTED
      end
      unless params[:password].present?
        return ERROR_PASSWORD1_IS_UNINPUTED
      end
      unless params[:user_id].size == USER_ID_FIGURE
        return ERROR_USERID_OR_PASS_IS_WRONG
      end
      user_id = params[:user_id].to_i
      crypted_password = Digest::MD5.hexdigest(params[:password])
      if !User.where(:id => user_id, :password => crypted_password).exists?
        return ERROR_USERID_OR_PASS_IS_WRONG
      end
      return NO_ERROR
    end
  end

  class BookmarkAuthenticator
    def self.authenticate(params)
      unless params[:game_id].present?
        return ERROR_USERID_IS_UNINPUTED
      end
      user = User.find_by_param_id(params[:game_id])
      unless user
        return ERROR_USERID_IS_UNREGISTERED
      end
      return NO_ERROR
    end
  end
end
