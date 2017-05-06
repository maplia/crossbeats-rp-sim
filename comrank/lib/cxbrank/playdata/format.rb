require 'cxbrank/site_settings'

module CxbRank
  module PlayData
    module Format
      def sprintf_for_level(level)
        return level == 0 ? '&ndash;' : sprintf(SiteSettings.level_format, level)
      end

      def sprintf_for_notes(notes)
        return notes == 0 ? '???' : sprintf('%d', notes)
      end
    end
  end
end
