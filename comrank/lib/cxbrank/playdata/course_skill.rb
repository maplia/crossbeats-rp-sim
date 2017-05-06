require 'cxbrank/const'
require 'cxbrank/master/course'
require 'cxbrank/playdata/base'

module CxbRank
  module PlayData
    class CourseSkill < PlayData::Base
      belongs_to :course, :class_name => 'Master::Course'

      validates_format_of :point_before_type_cast,
        :allow_nil => true, :allow_blank => true,
        :with => /\A\d+(\.\d+)?\z/, :message => ERRORS[ERROR_RP_NOT_NUMERIC]
      validate :validate_point_range
      validates_presence_of :rate,
        :if => (lambda do |a| a.played? and a.point.blank? end),
        :message => ERRORS[ERROR_RP_AND_RATE_NOT_EXIST]
      validates_format_of :rate_before_type_cast,
        :allow_nil => true, :allow_blank => true,
        :with => /\A\d+(\.\d+)?\z/, :message => ERRORS[ERROR_RATE_NOT_NUMERIC]
      validates_numericality_of :rate,
        :allow_nil => true, :allow_blank => true,
        :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100,
        :message => ERRORS[ERROR_RATE_OUT_OF_RANGE]

      def validate_point_range
        if point.blank?
          return true
        end
        if course.level > 0 and (point < 0.0 or point > course.level)
          errors.add(:point, ERRORS[ERROR_RP_OUT_OF_RANGE])
          return false
        else
          return true
        end
      end

      def self.last_modified(user)
        return self.where(:user_id => user.id).maximum(:updated_at)
      end

      def self.find_by_user(user, options={})
        skills = self.where(:user_id => user.id)
        if options[:fill_empty]
          courses = Master::Course.where(:display => true)
          courses.each do |course|
            unless CourseSkill.exists?(:user_id => user.id, :course_id => course.id)
              skill = CourseSkill.new
              skill.course = course
              skills << skill
            end
          end
        else
          skills = skills.to_a
          skills.delete_if do |skill| !skill.played? end
        end
        return skills
      end

      def self.find_by_user_and_course(user, course)
        skill = self.find_by(:user_id => user.id, :course_id => course.id)
        unless skill
          skill = self.new
          skill.user_id = user.id
          skill.course = course
        end
        return skill
      end

      def self.create_by_request(user, course, body)
        skill = self.find_by_user_and_course(user, course)
        skill.stat = body[:stat]
        skill.point = body[:point]
        skill.rate = body[:rate]
        skill.calc!
        return skill
      end

      def update_by_params!(params)
        if params.present?
          self.attributes = params
        end
      end

      def self.max(mode, course, date=nil)
        skill = self.new
        skill.course = course
        skill.stat = SP_STATUS_CLEAR
        skill.rate = 100
        skill.combo = SP_COMBO_STATUS_EX
        skill.calc!
        return skill
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
        @point_filled = false
        @rate_filled = false
        if played?
          if point.blank? and rate and (course.level > 0)
            calc_point = (course.level * BigDecimal.new((rate / 100.0).to_s)).floor(2)
            send('point=', calc_point)
            @point_filled = true
          elsif point and rate.blank? and (course.level > 0)
            calc_rate = (point / course.level).floor(3) * 100
            send('rate=', calc_rate)
            @rate_filled = true
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
        return SiteSettings.join_site_base(File.join(SKILL_COURSE_ITEM_EDIT_URI, course.text_id))
      end

      def point_to_s(nlv='&ndash;')
        return (played? ? sprintf('%.2f', point) : nlv)
      end

      def point_to_input_value
        if @point_filled
          return ''
        elsif point_before_type_cast.instance_of?(String)
          return point_before_type_cast
        else
          return (point ? point_to_s : '')
        end
      end

      def rate_to_s(nlv='&ndash;')
        if played? and rate
          if rate_f
            return sprintf('%.2f%%', rate)
          else
            return sprintf('%d%%', rate.to_i)
          end
        else
          return nlv
        end
      end

      def rate_to_input_value()
        if @rate_filled
          return ''
        elsif rate_before_type_cast.instance_of?(String)
          return rate_before_type_cast
        else
          return (rate ? rate_to_s.gsub(/%/, '') : '')
        end
      end

      def <=>(other)
        if (best_point || 0.0) != (other.best_point || 0.0)
          return -((best_point || 0.0) <=> (other.best_point || 0.0))
        else
          return course.sort_key <=> other.course.sort_key
        end
    end
    end
  end
end
