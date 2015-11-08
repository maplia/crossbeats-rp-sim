require 'rinku'
require 'cxbrank/const'

module CxbRank
	module Helpers
		class << self
			def registered app
				app.helpers do
					def site_top?
						return request.path_info.blank? || (request.path_info == CxbRank::SITE_TOP_URI)
					end

					def page_title(path_info=request.path_info)
						if path_info.blank? or path_info == SITE_TOP_URI
							return (mobile? ? '' : settings.site_name) + ' ' + PAGE_TITLES[SITE_TOP_URI]
						else
							return PAGE_TITLES[path_info]
						end
					end

					def mobile?
						return request.env['X_MOBILE_DEVICE'].present?
					end

					def cxb_mode?
						return settings.site_mode == MODE_CXB
					end

					def rev_mode?
						return settings.site_mode == MODE_REV
					end

					def music_diffs
						return MUSIC_DIFFS[settings.site_mode]
					end

					def music_types
						return MUSIC_TYPES[settings.site_mode]
					end

					def underscore(klass)
						return klass.to_s.underscore.gsub(/\//, '-') 
					end

					def multiline(text, autolink=false)
						result = simple_format(escape_html(text).gsub(/&#x2F;/, '/'))
						if autolink
							return Rinku.auto_link(result)
						else
							return result
						end
					end

					def find_template(views, name, engine, &block)
						Array(views).each do |v|
							super(v, name, engine, &block)
						end
					end
				end
			end
			alias :included :registered
		end
	end
end
