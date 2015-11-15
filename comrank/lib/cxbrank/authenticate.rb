require 'cxbrank/const'
require 'cxbrank/user'

module CxbRank
  class Authenticator
    def self.authenticate(params)
      if params[:user_id].empty?
        return ERROR_USERID_IS_UNINPUTED
      end
      if params[:password].empty?
        return ERROR_PASSWORD1_IS_UNINPUTED
      end
      unless params[:user_id].size == USER_ID_FIGURE
        return ERROR_USERID_OR_PASS_IS_WRONG
      end
      user = User.find_by_param_id(params[:user_id])
      unless user
        return ERROR_USERID_OR_PASS_IS_WRONG
      end
      if user.password != Digest::MD5.hexdigest(params[:password])
        return ERROR_USERID_OR_PASS_IS_WRONG
      end
      return NO_ERROR
    end
  end
end
