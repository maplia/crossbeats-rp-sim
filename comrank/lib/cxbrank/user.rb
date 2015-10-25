require 'erb'
require 'rubygems'
require 'active_record'
require 'util'
require 'cxbrank/util'
require 'cxbrank/const'

module CxbRank
	class User < ActiveRecord::Base
		include ErbFileRead
		include ERB::Util

		validates_confirmation_of :password

		def self.find_by_param_id(param_id)
			if param_id.size == USER_ID_FIGURE
				return self.find(param_id.to_i)
			else
				return self.find(:first,
					:conditions => {:game_id => param_id}, :order => 'point_updated_at desc')
			end
		end

		def validate
			if name.empty?
				return ERROR_USERNAME_IS_UNINPUTED
			end
			if password.empty?
				return ERROR_PASSWORD1_IS_UNINPUTED
			end
			if password_confirmation and password_confirmation.empty?
				return ERROR_PASSWORD2_IS_UNINPUTED
			end
			if password_confirmation and password != password_confirmation
				return ERROR_PASSWORDS_ARE_NOT_EQUAL
			end
			unless point_before_type_cast.is_f?
				return ERROR_REAL_RP_NOT_NUMERIC
			end

			return NO_ERROR
		end

		def user_id
			return sprintf('%0*d', USER_ID_FIGURE, id)
		end

		def skill_view_uri
			return "#{SKILL_LIST_VIEW_URI}/#{user_id}"
		end

		def skill_ignore_uri
			return "#{SKILL_LIST_VIEW_IGLOCK_URI}/#{user_id}"
		end

		def skill_chart_uri
			return "#{CLEAR_LIST_VIEW_URI}/#{user_id}"
		end

		def to_html(edit)
			template_html = 'user/user_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_edit
			template_html = 'user/user_edit_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_confirm
			template_html = 'user/user_edit_item_conf.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_hash
			return {
				:user_id => user_id, :name => name,
			}
		end

		def <=>(other)
			return (point_updated_at || Time.parse('1970-01-01')) <=> (other.point_updated_at || Time.parse('1970-01-01'))
		end
	end
end
