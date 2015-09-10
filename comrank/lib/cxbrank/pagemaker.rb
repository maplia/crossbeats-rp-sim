require 'erb'
require 'cxbrank/util'

module CxbRank
	class PageMaker
		include ErbFileRead
		include ERB::Util

		private
		def session_alive?
			return (@session and (@session[:temp_user] or @session[:user]))
		end

		def read_template
			layout = read_erb_file('layout.html.erb')
			return layout.gsub(/<!--BODY-->/, read_erb_file(@template_html, @basedir))
		end

		def make_tracker
			return ERB.new(read_erb_file('tracker.html.erb')).result(binding)
		end

		def make_error_page(error_no, back_uri=nil)
			@template_html = 'error.html.erb'
			page_title = 'エラー'
			return ERB.new(read_template).result(binding)
		end
	end
end
