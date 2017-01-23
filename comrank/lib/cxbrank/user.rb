require 'digest/md5'
require 'active_record'
require 'cxbrank/const'

module CxbRank
  class User < ActiveRecord::Base
    validates_presence_of :name, :message => ERRORS[ERROR_USERNAME_IS_UNINPUTED]
    validates_presence_of :password, :message => ERRORS[ERROR_PASSWORD1_IS_UNINPUTED]
    validates_confirmation_of :password, :message => ERRORS[ERROR_PASSWORDS_ARE_NOT_EQUAL]
    validates_format_of :game_id, :allow_nil => true, :allow_blank => true,
      :with => /\A\d+\z/, :message => ERRORS[ERROR_GAME_ID_NOT_NUMERIC]
    validates_length_of :game_id, :allow_nil => true, :allow_blank => true,
      :is => GAME_ID_FIGURE, :message => ERRORS[ERROR_GAME_ID_LENGTH_IS_INVALID]
    validates_format_of :point_before_type_cast, :allow_nil => true, :allow_blank => true,
      :with => /\A\d+(\.\d+)?\z/, :message => ERRORS[ERROR_REAL_RP_NOT_NUMERIC]
    validates_presence_of :point, :if => (lambda do |a| SiteSettings.rev_mode? and a.id end),
      :message => ERRORS[ERROR_REAL_RP_IS_UNINPUTED]

    before_save do |b|
      if b.password_changed?
        b.password = User.crypt(b.password)
      end
    end

    def self.authenticate(user_id, password)
      return self.where(:id => user_id.to_i, :password => self.crypt(password)).exists?
    end

    def self.crypt(string)
      return Digest::MD5.hexdigest(string)
    end

    def self.last_modified
      return self.maximum(:updated_at)
    end

    def self.find_by_param_id(param_id)
      if param_id.size == USER_ID_FIGURE
        return self.where(:id => param_id.to_i).first
      else
        return self.where(:game_id => param_id).order('point_updated_at desc').first
      end
    end

    def self.find_actives
      return self.where(:display => true).where('point_updated_at is not null').order('point_updated_at desc')
    end

    def self.create_by_params(params)
      user = self.new
      user.attributes = params
      user.comment.gsub!(/\r\n/, "\n") if user.comment.present?
      return user
    end

    def update_by_params!(params)
      if params.present?
        before_password = password
        self.attributes = params
        self.comment.gsub!(/\r\n/, "\n") if comment.present?
        if password.blank?
          self.password = before_password
        end
        if password_confirmation.blank?
          self.password_confirmation = before_password
        end
        self.point_direct = point_changed?
      end
    end

    def user_id
      return sprintf('%0*d', USER_ID_FIGURE, id)
    end

    def skill_view_uri
      return SiteSettings.join_site_base(File.join(SKILL_LIST_VIEW_URI, user_id))
    end

    def skill_ignore_uri
      return SiteSettings.join_site_base(File.join(SKILL_LIST_VIEW_IGLOCK_URI, user_id))
    end

    def skill_chart_uri
      return SiteSettings.join_site_base(File.join(CLEAR_LIST_VIEW_URI, user_id))
    end

    def to_hash
      return {
        :user_id => user_id, :name => name,
      }
    end

    def <=>(other)
      return (point_updated_at || Time.parse('1970-01-01')) <=> (other.point_updated_at || Time.parse('1970-01-01'))
    end
  end
end
