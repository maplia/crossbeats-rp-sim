require 'rubygems'
require 'rinku'

class String
	def is_i?
		begin
			Integer(self)
			return true
		rescue ArgumentError
			return false
		end
	end

	def is_f?
		begin
			Float(self)
			return true
		rescue ArgumentError
			return false
		end
	end
end

class Float
	def is_f?
		return true
	end
end

class Integer
	def is_f?
		return true
	end

	def is_i?
		return true
	end
end

def hash_to_option_html(hash, default=nil)
	html = ''
	default = hash.keys.min unless default

	hash.keys.sort.each do |key|
		html << "<option value=\"#{key}\""
		html << " selected" if default == key
		html << ">#{hash[key]}</option>"
	end

	return html
end

def normalize_textarea_data(data)
	return data.gsub(/\r\n/, "\n")
end

def textarea_data_to_html(data, autolink=false)
	if data
		html = data.dup
		html.gsub!(/(\r\n|\r|\n)/, '<br/>')
		html = Rinku.auto_link(html) if autolink
	else
		html = data
	end
	return html
end
