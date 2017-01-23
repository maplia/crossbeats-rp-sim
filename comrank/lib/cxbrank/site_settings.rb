require 'chronic'
require 'cxbrank/const'

module CxbRank
  class SiteSettings
    @@settings = nil
    @@pivot_date = nil
    @@pivot_time = nil

    def self.settings=(settings)
      @@settings = settings
    end

    def self.pivot_date=(date)
      @@pivot_date = date
      @@pivot_time = Chronic.parse(date.strftime('%Y-%m-%d 27:59:59'))
    end

    def self.pivot_date
      return @@pivot_date
    end

    def self.pivot_time
      return @@pivot_time
    end

    def self.join_site_base(uri)
      return File.join(@@settings.site_base || '', uri)
    end

    def self.join_site_image_base(uri)
      return File.join(@@settings.site_image_base || '', uri)
    end

    def self.join_site_style_base(uri)
      return File.join(@@settings.site_style_base || '', uri)
    end

    def self.join_common_style_base(uri)
      return File.join(@@settings.common_style_base || '', uri)
    end

    def self.join_common_script_base(uri)
      return File.join(@@settings.common_script_base || '', uri)
    end

    def self.join_comrank_path(path)
      return File.join(@@settings.comrank_path || '', path)
    end

    def self.cxb_mode?
      return @@settings.site_mode.start_with?(MODE_CXB)
    end

    def self.rev_mode?
      return @@settings.site_mode.start_with?(MODE_REV)
    end

    def self.rev_rev1st_mode?
      return rev_mode? && !rev_sunrise_mode?
    end
    
    def self.rev2nd_or_later_mode?
      return !cxb_mode? && !rev_rev1st_mode?
    end

    def self.rev_sunrise_mode?
      return @@settings.site_mode == MODE_REV_SUNRISE
    end

    def self.music_diffs
      return MUSIC_DIFFS[@@settings.site_mode]
    end

    def self.music_types
      return MUSIC_TYPES[@@settings.site_mode]
    end

    def self.level_format
      return LEVEL_FORMATS[@@settings.site_mode]
    end

    def self.date_low_limit
      return DATE_LOW_LIMITS[@@settings.site_mode]
    end

    def self.legacy_chart_enabled?
      return @@settings.legacy_chart
    end
  end
end
