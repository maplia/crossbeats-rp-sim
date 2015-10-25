require 'securerandom'
require 'rubygems'
require 'active_record'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/skill'

module CxbRank
	class BookmarkletSession < ActiveRecord::Base
		belongs_to :user
	end

	class JsonLog < ActiveRecord::Base
	end

	class BookmarkletExecutor
		def get_session(key)
			return BookmarkletSession.find(:first, :conditions => {:key => key})
		end

		def get_user(key)
			session = get_session(key)
			return session ? session.user : nil
		end
	end

	class BookmarkletAuthenticator
		def initialize(params)
			@params = params
		end

		def execute
			unless @params[:game_id]
				return {:status => 401}
			end

			user = User.find_by_param_id(@params[:game_id])
			unless user
				return {:status => 401}
			end

			bml_session = BookmarkletSession.new
			bml_session.user_id = user.id
			bml_session.key = SecureRandom.hex(32)
			begin
				bml_session.save!
			rescue
				return {:status => 500}
			end

			return {:status => 200, :key => bml_session.key, :user_id => user.user_id}
		end
	end

	class BookmarkletMasterUpdater < BookmarkletExecutor
		def initialize(data)
			@data = data
		end

		def execute
			unless get_session(@data[:key])
				return {:status => 401}
			end

			body = @data[:body]
			case @data[:type]
			when 'music'
				item = MusicEdit.find(:first, :conditions => {:lookup_key => body[:lookup_key]})
				unless item
					item = MusicEdit.new
					item.number = 0
					item.text_id = body[:text_id]
					item.title = body[:title]
					item.sort_key = body[:sort_key]
					item.lookup_key = body[:lookup_key]
					item.limited = 0
				end
				$config.music_diffs.keys.each do |diff|
					diff_name = $config.music_diffs[diff].downcase
					next unless body[diff_name.to_sym]
					item.send("#{diff_name}_level=", body[diff_name.to_sym][:level])
					item.send("#{diff_name}_notes=", body[diff_name.to_sym][:notes])
				end
			when 'course'
				item = Course.find(:first, :conditions => {:lookup_key => body[:lookup_key]})
				unless item
					item = Course.new
					item.text_id = body[:lookup_key]
					item.name = body[:lookup_key]
					item.level = 0
					item.sort_key = body[:lookup_key]
					item.lookup_key = body[:lookup_key]
				end
			end

			item.save!

			return {:status => 200}
		end
	end

	class BookmarkletSkillEditor < BookmarkletExecutor
		def initialize(data)
			@data = data
		end

		def execute
			if @data.nil? or @data[:key].nil? or @data[:lookup_key].nil? or @data[:body].nil?
				return {:status => 400}
			end

			user = get_user(@data[:key])
			unless user
				return {:status => 401}
			end

			lookup_key = @data[:lookup_key]
			body = @data[:body]

			case @data[:type]
			when 'music'
				music = Music.find(:first, :conditions => {:lookup_key => lookup_key})
				unless music
					return {:status => 400}
				end
				skill = Skill.find(:first,
					:conditions => {:user_id => user.id, :music_id => music.id})
				unless skill
					skill = Skill.new
					skill.user_id = user.id
					skill.music = music
				end
				body.keys.each do |diff_name|
					skill.send("#{diff_name}_stat=", body[diff_name.to_sym][:stat])
					skill.send("#{diff_name}_point=", body[diff_name.to_sym][:point])
					skill.send("#{diff_name}_rate=", body[diff_name.to_sym][:rate])
					skill.send("#{diff_name}_rate_f=", 1)
					skill.send("#{diff_name}_rank=", body[diff_name.to_sym][:rank])
					skill.send("#{diff_name}_combo=", body[diff_name.to_sym][:combo])
					skill.send("#{diff_name}_gauge=", body[diff_name.to_sym][:gauge])
				end
			when 'course'
				course = Course.find(:first, :conditions => {:lookup_key => lookup_key})
				unless course
					return {:status => 400}
				end
				skill = CourseSkill.find(:first,
					:conditions => {:user_id => user.id, :course_id => course.id})
				unless skill
					skill = CourseSkill.new
					skill.user_id = user.id
					skill.course = course
				end
				skill.stat = body[:stat]
				skill.point = body[:point]
			end
			skill.calc!

			if skill.id or (skill.best_point || 0.0) > 0.0
				skill.save!
			end

			return {:status => 200}
		end
	end

	class BookmarkletPointEditor < BookmarkletExecutor
		def initialize(data)
			@data = data
		end

		def execute
			if @data.nil? or @data[:key].nil? or @data[:body].nil?
				return {:status => 400}
			end

			user = get_user(@data[:key])
			unless user
				return {:status => 401}
			end

			body = @data[:body]
			user.point = body[:point]
			user.point_direct = true
			user.point_updated_at = Time.now

			user.save!

			return {:status => 200}
		end
	end

	class BookmarkletSessionTerminator < BookmarkletExecutor
		def initialize(params)
			@params = params
		end

		def execute
			session = get_session(@params[:key])
			unless session
				return {:status => 401}
			end

			session.destroy

			return {:status => 200}
		end
	end
end
