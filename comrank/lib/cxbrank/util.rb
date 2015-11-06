require 'yaml'
require 'rubygems'
require 'cxbrank/const'

module CxbRank
	class SiteConfig
		def initialize
			@config = YAML.load_file(CONFIGURATION_FILE)
		end

		def name
			return @config['site_name']
		end

		def mode
			return @config['site_mode']
		end

		def style
			return $mobile ? @config['style_sp'] : @config['style_pc'] 
		end

		def cxb_mode?
			return mode == MODE_CXB
		end

		def rev_mode?
			return mode == MODE_REV
		end
		
		def music_types
			return MUSIC_TYPES[mode]
		end
		
		def music_diffs
			return MUSIC_DIFFS[mode]
		end

		def level_format
			return LEVEL_FORMATS[mode]
		end

		def view_basedir
			return '../comrank/views'
		end

		def tracker_id
			return @config['tracker_id']
		end

		def tracker_domain
			return @config['domain']
		end

		def session_key
			return @config['session_key']
		end

		def secret
			return @config['secret']
		end
	end

	module ErbFileRead
		def read_erb_file(filename, basedir=nil)
			mobile_filename = filename.gsub(/\.html\.erb/, '.mobile.html.erb')
			if $mobile and File.exist?(File.join((basedir || $config.view_basedir), mobile_filename))
				html = File.open(File.join((basedir || $config.view_basedir), mobile_filename)).read
			else
				html = File.open(File.join((basedir || $config.view_basedir), filename)).read
			end
			return html
		end
	end
end
