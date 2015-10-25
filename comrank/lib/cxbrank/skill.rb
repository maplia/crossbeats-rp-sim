require 'erb'
require 'bigdecimal'
require 'rubygems'
require 'active_record'
require 'cxbrank/util'
require 'cxbrank/user'
require 'cxbrank/music'

module CxbRank
	class Skill < ActiveRecord::Base
		include Comparable
		include ErbFileRead
		include ERB::Util
		belongs_to :music

		@@ignore_locked = false

		def self.ignore_locked=(ignore_locked)
			@@ignore_locked = ignore_locked
		end

		def self.ignore_locked
			return @@ignore_locked
		end

		def self.last_modified(user)
			skill = self.find(:first, :conditions => {:user_id => user.id}, :order => 'updated_at desc')
			return (skill ? skill.updated_at : nil)
		end

		def validate
			$config.music_diffs.keys.sort.each do |diff|
				next unless music.exist?(diff)

				if cleared?(diff) and point(diff).nil? and rate(diff).nil?
					return SKILL_ERRORS[diff][ERROR_RP_AND_RATE_NOT_EXIST]
				end

				if point(diff)
					unless send("#{$config.music_diffs[diff].downcase}_point_before_type_cast").is_f?
						return SKILL_ERRORS[diff][ERROR_RP_NOT_NUMERIC]
					end
					max_point = music.level(diff)
					max_point *= BONUS_RATE_SURVIVAL if survival?(diff)
					max_point *= BONUS_RATE_ULTIMATE if ultimate?(diff)
					if (point(diff) * 100).round < 0 or (point(diff) * 100).round > (max_point * 100).round
						return SKILL_ERRORS[diff][ERROR_RP_OUT_OF_RANGE]
					end
				end

				if rate(diff)
					unless send("#{$config.music_diffs[diff].downcase}_rate_before_type_cast").is_f?
						return SKILL_ERRORS[diff][ERROR_RATE_NOT_NUMERIC]
					end
					unless (0..100).include?(rate(diff))
						return SKILL_ERRORS[diff][ERROR_RATE_OUT_OF_RANGE]
					end
				end
			end

			return NO_ERROR
		end

		def stat(diff)
			return send("#{$config.music_diffs[diff].downcase}_stat")
		end

		def point(diff)
			return send("#{$config.music_diffs[diff].downcase}_point")
		end

		def rate(diff)
			return send("#{$config.music_diffs[diff].downcase}_rate")
		end

		def rank(diff)
			return send("#{$config.music_diffs[diff].downcase}_rank")
		end

		def combo(diff)
			return send("#{$config.music_diffs[diff].downcase}_combo")
		end

		def gauge(diff)
			return send("#{$config.music_diffs[diff].downcase}_gauge")
		end

		def locked(diff)
			return send("#{$config.music_diffs[diff].downcase}_locked")
		end

		def cleared?(diff)
			return stat(diff) == SP_STATUS_CLEAR
		end

		def failed?(diff)
			return stat(diff) == SP_STATUS_FAILED
		end

		def fullcombo?(diff)
			return [SP_COMBO_STATUS_FC, SP_COMBO_STATUS_EX].include?(combo(diff))
		end

		def survival?(diff)
			if $config.cxb_mode?
				return false
			else
				return send("#{$config.music_diffs[diff].downcase}_gauge") == SP_GAUGE_SURVIVAL
			end
		end

		def ultimate?(diff)
			if $config.cxb_mode?
				return send("#{$config.music_diffs[diff].downcase}_gauge") == SP_GAUGE_ULTIMATE_CXB
			else
				return send("#{$config.music_diffs[diff].downcase}_gauge") == SP_GAUGE_ULTIMATE
			end
		end

		def locked?(diff)
			return locked(diff) == 1
		end

		def rate_is_f?(diff)
			return send("#{$config.music_diffs[diff].downcase}_rate_f") == 1
		end

		def u_rate(diff)
			unless survival?(diff) or ultimate?(diff)
				return nil
			else
				if survival?(diff)
					max_point = music.level(diff) * BONUS_RATE_SURVIVAL
				elsif ultimate?(diff)
					max_point = music.level(diff) * BONUS_RATE_ULTIMATE
				end
				return [((point(diff) || 0.0) / max_point * 100).ceil, rate(diff)].min
			end
		end

		def calc!
			send("best_diff=", nil)
			send("best_point=", 0.0)
			send("iglock_best_diff=", nil)
			send("iglock_best_point=", 0.0)

			$config.music_diffs.keys.each do |diff|
				if music.exist?(diff)
					if point(diff).nil? and rate(diff)
						temp_point = music.level(diff) * ((rate(diff) ? rate(diff).to_i : 0) / 100.0)
						if survival?(diff)
							temp_point = temp_point * BONUS_RATE_SURVIVAL
						elsif ultimate?(diff)
							temp_point = temp_point * BONUS_RATE_ULTIMATE
						end
						temp_point = BigDecimal.new((temp_point * 100).to_s).truncate.to_f / 100.0
						send("#{$config.music_diffs[diff].downcase}_point=", temp_point)
					end

					if (iglock_best_point || 0.0) < (point(diff) || 0.0)
						send("iglock_best_diff=", diff)
						send("iglock_best_point=", point(diff))
					end
					if (best_point || 0.0) < (point(diff) || 0.0) and !locked?(diff)
						send("best_diff=", diff)
						send("best_point=", point(diff))
					end
				end
			end
		end

		def rp_target=(flag)
			@target = flag
		end

		def rp_target?
			return @target == true
		end

		def target_diff
			return @@ignore_locked ? iglock_best_diff : (best_diff == iglock_best_diff ? best_diff : iglock_best_diff)
		end

		def target_point
			return @@ignore_locked ? iglock_best_point : best_point
		end

		def edit_uri
			return "#{SKILL_ITEM_EDIT_URI}/#{music.text_id}"
		end

		def point_to_s(diff, nlv='&ndash;')
			return cleared?(diff) ? sprintf('%.2f', point(diff)) : nlv
		end

		def point_bonus_to_s(diff, nlv='&ndash;')
			return cleared?(diff) ? sprintf('%.2f', BigDecimal((point(diff) * BONUS_RATE_UNLIMITED).to_s).floor(2)) : nlv
		end

		def rate_to_s(diff, nlv='&ndash;')
			unless cleared?(diff)
				return nlv
			else
				if rate_is_f?(diff)
					return sprintf('%d<small>.%02d</small>%%', rate(diff).to_i, (rate(diff) * 100).to_i % 100)
				else
					return sprintf('%d%%', rate(diff).to_i)
				end
			end
		end

		def u_rate_to_s(diff, nlv='')
			unless cleared?(diff)
				return nlv
			else
				if $config.rev_mode?
					mark = (survival?(diff) ? 'S' : (ultimate?(diff) ? 'U' : ''))
				else
					mark = ''
				end
				return (mark.size.nonzero? ? sprintf('%s %d%%', mark, u_rate(diff)) : '')
			end
		end

		def to_html(edit, row, bonus=false)
			template_html = 'skill/skill_list_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_exist
			return to_html_confirm
		end

		def to_html_confirm(before=nil)
			template_html = 'skill/skill_edit_item_conf.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_edit
			template_html = 'skill/skill_edit_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_chart
			template_html = 'skill/skill_chart_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def <=>(other)
			if @@ignore_locked
				if (iglock_best_point || 0.0) != (other.iglock_best_point || 0.0)
					return -((iglock_best_point || 0.0) <=> (other.iglock_best_point || 0.0))
				else
					return music.sort_key <=> other.music.sort_key
				end
			else
				if (best_point || 0.0) != (other.best_point || 0.0)
					return -((best_point || 0.0) <=> (other.best_point || 0.0))
				elsif (iglock_best_point || 0.0) != (other.iglock_best_point || 0.0)
					return -((iglock_best_point || 0.0) <=> (other.iglock_best_point || 0.0))
				else
					return music.sort_key <=> other.music.sort_key
				end
			end
		end
	end

	class CourseSkill < ActiveRecord::Base
		include Comparable
		include ErbFileRead
		include ERB::Util
		belongs_to :course

		def self.last_modified(user)
			skill = self.find(:first, :conditions => {:user_id => user.id}, :order => 'updated_at desc')
			return (skill ? skill.updated_at : nil)
		end

		def validate
			if cleared? and point.nil? and rate.nil?
				return ERROR_RP_AND_RATE_NOT_EXIST
			end

			if point
				unless point_before_type_cast.is_f?
					return ERROR_RP_NOT_NUMERIC
				end
				max_point = course.level
				if (point * 100).round < 0 or (point * 100).round > (max_point * 100).round
					return ERROR_RP_OUT_OF_RANGE
				end
			end

			if rate
				unless rate_before_type_cast.is_f?
					return ERROR_RATE_NOT_NUMERIC
				end
				unless (0..100).include?(rate)
					return ERROR_RATE_OUT_OF_RANGE
				end
			end

			return NO_ERROR
		end

		def best_point
			return point
		end

		def iglock_best_point
			return point
		end

		def target_point
			return point
		end

		def cleared?
			return stat == SP_COURSE_STATUS_CLEAR
		end

		def played?
			return stat != SP_COURSE_STATUS_NO_PLAY
		end

		def calc!
			if played?
				if point.nil? and rate
					temp_point = course.level * ((rate || 0.0) / 100.0)
					temp_point = BigDecimal.new((temp_point * 100).to_s).truncate.to_f / 100.0
					send("point=".to_sym, temp_point)
				elsif point and rate.nil?
					send("rate=".to_sym, (point / course.level * 1000).truncate.to_f / 10.0)
				end
			end
		end

		def rp_target=(flag)
			@target = flag
		end

		def rp_target?
			return @target == true
		end

		def edit_uri
			return "#{SKILL_COURSE_ITEM_EDIT_URI}/#{course.text_id}"
		end

		def point_to_s(nlv='&ndash;')
			return (played? ? sprintf('%.2f', point) : nlv)
		end

		def rate_to_s(nlv='&ndash;')
			return (played? ? sprintf('%.1f%%', rate) : nlv)
		end

		def to_html(edit, row, dummy=false)
			template_html = 'course/course_list_item.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_exist
			return to_html_confirm
		end

		def to_html_confirm(before=nil)
			template_html = 'course/course_skill_item_conf.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def to_html_edit
			template_html = 'course/course_skill_item_edit.html.erb'
			return ERB.new(read_erb_file(template_html)).result(binding)
		end

		def <=>(other)
			if (best_point || 0.0) != (other.best_point || 0.0)
				return -((best_point || 0.0) <=> (other.best_point || 0.0))
			else
				return course.sort_key <=> other.course.sort_key
			end
		end
	end

	class SkillSet
		attr_reader :skill_hash, :point_hash

		def initialize(skill_hash, point_hash)
			@skill_hash = skill_hash
			@point_hash = point_hash
		end

		def self.find_by_user(user, options={})
			music_skills = Skill.find(:all, :conditions => {:user_id => user.id})
			if options[:fill_empty]
				musics = Music.find(:all)
				musics.each do |music|
					unless Skill.exists?({:user_id => user.id, :music_id => music.id})
						music_skill = Skill.new
						music_skill.music = music
						music_skills << music_skill
					end
				end
			end
			music_skills.sort!

			if $config.rev_mode?
				course_skills = CourseSkill.find(:all, :conditions => {:user_id => user.id})
				if options[:fill_empty]
					courses = Course.find(:all)
					courses.each do |course|
						unless CourseSkill.exists?({:user_id => user.id, :course_id => course.id})
							course_skill = CourseSkill.new
							course_skill.course = course
							course_skills << course_skill
						end
					end
				end
				course_skills.sort!
			end

			skill_hash = {}
			if $config.rev_mode?
				skill_hash[MUSIC_TYPE_REV_SINGLE] = music_skills
				skill_hash[MUSIC_TYPE_REV_BONUS] = []
				skill_hash[MUSIC_TYPE_REV_COURSE] = course_skills
			else
				skill_hash[MUSIC_TYPE_NORMAL] = []
				skill_hash[MUSIC_TYPE_SPECIAL] = []
				music_skills.each do |skill|
					if skill.music.monthly?
						skill_hash[MUSIC_TYPE_SPECIAL] << skill
					else
						skill_hash[MUSIC_TYPE_NORMAL] << skill
					end
				end
			end

			point_hash = {}
			skill_hash.each do |type, skills|
				next if type == MUSIC_TYPE_REV_BONUS
				point_hash[type] = 0.0

				skills[0..(MUSIC_TYPE_ST_COUNTS[type]) - 1].each do |skill|
					next if (skill.target_point || 0.0) == 0.0
					point_hash[type] += skill.target_point
					skill.rp_target = true
				end
			end

			music_skills.each do |skill|
				if !skill.rp_target? and skill.cleared?(MUSIC_DIFF_UNL)
					skill_hash[MUSIC_TYPE_REV_BONUS] << skill
				end
			end
			skill_hash[MUSIC_TYPE_REV_BONUS].sort! do |a, b|
				if a.locked?(MUSIC_DIFF_UNL) != b.locked?(MUSIC_DIFF_UNL)
					(a.locked?(MUSIC_DIFF_UNL) ? 1 : 0) <=> (b.locked?(MUSIC_DIFF_UNL) ? 1 : 0)
				else
					-a.point(MUSIC_DIFF_UNL) <=> -b.point(MUSIC_DIFF_UNL)
				end
			end

			if user.point_direct
				point_hash[MUSIC_TYPE_REV_BONUS] = user.point - point_hash[MUSIC_TYPE_REV_SINGLE] - point_hash[MUSIC_TYPE_REV_COURSE]
			else
				point_hash[MUSIC_TYPE_REV_BONUS] = 0.0
				skill_hash[MUSIC_TYPE_REV_BONUS].each do |skill|
					if Skill.ignore_locked or !skill.locked?(MUSIC_DIFF_UNL)
						point_hash[MUSIC_TYPE_REV_BONUS] += skill.point(MUSIC_DIFF_UNL) * BONUS_RATE_UNLIMITED
					end
				end
				point_hash[MUSIC_TYPE_REV_BONUS] = (point_hash[MUSIC_TYPE_REV_BONUS] * 100.0).to_i / 100.0
			end

			return self.new(skill_hash, point_hash)
		end

		def total_point
			total_point = 0.0
			@point_hash.values.each do |point|
				total_point += point
			end
			return total_point
		end
	end
end
