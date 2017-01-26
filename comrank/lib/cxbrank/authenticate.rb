require 'cxbrank/const'
require 'cxbrank/user'

module CxbRank
  class BookmarkletAuthenticator
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
