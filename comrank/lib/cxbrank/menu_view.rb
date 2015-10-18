require 'erb'
require 'cxbrank/pagemaker'

module CxbRank
	class SiteTopMaker < PageMaker
		def initialize
			@template_html = 'index.html.erb'
			@basedir = 'views'
		end

		def last_modified
			return [
				File.mtime(File.join(@basedir, 'index.html.erb')),
				File.mtime(File.join(@basedir, 'index_news.html.erb')),
			].max;
		end

		def to_html
			page_title = nil
			return ERB.new(read_template).result(binding)
		end
	end
end
