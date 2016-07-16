require 'uri'
require 'rinku'
require 'action_view/helpers'
require 'cxbrank/const'

module CxbRank
  module Helpers
    class << self
      def registered app
        app.helpers do
          def site_top?
            return request.path_info.blank? || (request.path_info == SITE_TOP_URI)
          end

          def page_title(path_info=request.path_info)
            if path_info.blank? or path_info == SITE_TOP_URI
              return (mobile? ? '' : settings.site_name) + ' ' + PAGE_TITLES[SITE_TOP_URI]
            else
              return PAGE_TITLES["/#{path_info.split('/')[1]}"]
            end
          end

          def mobile?
            return request.env['X_MOBILE_DEVICE'].present?
          end

          def underscore(klass)
            return klass.to_s.underscore.gsub(/\//, '-') 
          end

          def multiline(text, autolink=false)
            result = escape_html(text).gsub(/&#x2F;/, '/')
            result.gsub!(/\r\n|\r|\n/, '<br />')
            if autolink
              return Rinku.auto_link(result)
            else
              return result
            end
          end

          def strftime_over24(time, format, dateline)
            if time.hour >= dateline
              return time.strftime(format)
            else
              yesterday = time - 60*60*24*1
              yesterday_format = format.gsub(/%H/, (time.hour+24).to_s)
              return yesterday.strftime(yesterday_format)
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
