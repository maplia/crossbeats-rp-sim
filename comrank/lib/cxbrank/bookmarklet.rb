require 'securerandom'
require 'rubygems'
require 'active_record'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/course'
require 'cxbrank/skill'

module CxbRank
	class BookmarkletSession < ActiveRecord::Base
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

	class BookmarkletMasterUpdater
		def initialize(data)
			@data = data
		end

		def execute
			unless BookmarkletSession.exists?({:key => @data[:key]})
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

			begin
				item.save!
			rescue
				return {:status => 500}
			end

			return {:status => 200}
		end
	end

	class BookmarkletSkillEditor
		def initialize(data)
			@data = data
		end

		def execute
			if @data.nil? or @data[:key].nil? or @data[:lookup_key].nil? or @data[:body].nil?
				return {:status => 400}
			end
			
			session = BookmarkletSession.find(:first, :conditions => {:key => @data[:key]})
			unless session
				return {:status => 401}
			end
			user = User.find(session.user_id)

			lookup_key = @data[:lookup_key]
			body = @data[:body]

			case @data[:type]
			when 'music'
				music = Music.find(:first, :conditions => {:lookup_key => lookup_key})
				unless music
					return {:status => 400}
				end
				skill = Skill.find(:first,
					:conditions => {:user_id => session.user_id, :music_id => music.id})
				unless skill
					skill = Skill.new
					skill.user_id = user.user_id
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
					:conditions => {:user_id => session.user_id, :course_id => course.id})
				unless skill
					skill = CourseSkill.new
					skill.user_id = user.user_id
					skill.course = course
				end
				skill.stat = body[:stat]
				skill.point = body[:point]
			end
			skill.calc!

			if skill.id or skill.best_point > 0.0
				begin
					skill.save!
				rescue
					return {:status => 500}
				end
				skill_set = SkillSet.find_by_user(user)
				user.point = skill_set.total_point
				user.point_updated_at = [Skill.last_modified(user), CourseSkill.last_modified(user)].max
				begin
					user.save!
				rescue
					return {:status => 500}
				end
			end

			return {:status => 200}
		end
	end

	class BookmarkletSessionTerminator
		def initialize(params)
			@params = params
		end

		def execute
			unless @params[:key]
				return {:status => 401}
			end

			bml_session = BookmarkletSession.find(:first, :conditions => {:key => @params[:key]})
			unless bml_session
				return {:status => 401}
			end
			bml_session.delete

			return {:status => 200}
		end
	end
end
