require 'erb'
require 'cxbrank/pagemaker'
require 'cxbrank/user'

module CxbRank
	class UserListMaker < PageMaker
		def initialize(mobile)
			@mobile = mobile
			@template_html = 'user/user_list.html.erb'
		end

		def last_modified
			return User.maximum('updated_at')
		end

		def to_html
			users = User.find(:all,
				:conditions => 'display = 1 and point_updated_at is not null')
			users.sort!
			users.reverse!
			page_title = '登録ユーザー一覧'

			return ERB.new(read_template).result(binding)
		end
	end
end
