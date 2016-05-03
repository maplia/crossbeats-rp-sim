require 'cxbrank/const'

module CxbRank
  class SiteSettings
    @@settings = nil

    def self.settings=(settings)
      @@settings = settings
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

    def self.join_site_common_script_base(uri)
      return File.join(@@settings.site_common_script_base || '', uri)
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

    def self.music_diffs
      return MUSIC_DIFFS[@@settings.site_mode]
    end

    def self.music_types
      return MUSIC_TYPES[@@settings.site_mode]
    end

    def self.level_format
      return LEVEL_FORMATS[@@settings.site_mode]
    end

    def self.legacy_chart_enabled?
      return @@settings.legacy_chart
    end
  end
end
