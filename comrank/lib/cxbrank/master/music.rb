require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/master/playable'
require 'cxbrank/master/legacy_chart'
require 'cxbrank/master/monthly'

module CxbRank
  module Master
    class Music < Playable
      include Comparable
      has_one :monthly, -> {where 'span_s <= ? and span_e >= ?',
        SiteSettings.pivot_time, SiteSettings.pivot_time}
      has_one :legacy_chart, -> {where 'span_s <= ? and span_e >= ?',
        SiteSettings.pivot_date, SiteSettings.pivot_date}

      def self.create_by_request(body)
        music = self.find_by(:lookup_key => body[:lookup_key])
        unless music
          music = self.new
          music.number = 0
          music.text_id = body[:text_id]
          music.title = body[:title]
          music.sort_key = body[:sort_key]
          music.lookup_key = body[:lookup_key]
          music.limited = false
          music.hidden = true
          music.unlock_unl = UNLOCK_UNL_TYPE_SP
          music.appear = REV_VERSION_SUNRISE
          music.category = REV_CATEGORY_ORIGINAL
          music.added_at = Date.today
        end
        music.jacket = body[:jacket]
        MUSIC_DIFF_PREFIXES.values.each do |prefix|
          next unless body[prefix.to_sym]
          music.send("#{prefix}_level=", body[prefix.to_sym][:level])
          music.send("#{prefix}_notes=", body[prefix.to_sym][:notes])
        end
        if music.unl_level_changed?
          music.unlock_unl = UNLOCK_UNL_TYPE_SP
          music.added_at_unl = Date.today
        end
        return music
      end

      def self.find_actives(without_deleted)
        if SiteSettings.sunrise_or_later_mode?
          return super(without_deleted, :appear, :sort_key)
        else
          return super(without_deleted, :number, :sort_key)
        end
      end

      def self.find_recents
        return self.public_method(:find_actives)
          .super_method.call(true, 'added_at desc', :number, :sort_key)
          .where(:limited => false).where('added_at >= ?', Date.today - (4*7))
      end

      def self.find_recents_unl
        return self.public_method(:find_actives)
          .super_method.call(true, 'added_at desc', :number, :sort_key)
          .where(:limited => false).where('added_at_unl >= ?', Date.today - (8*7))
      end

      def full_title
        return subtitle ? "#{title} #{subtitle}" : title
      end

      def level(diff)
        if legacy_chart.present?
          return legacy_chart.level(diff)
        else
          return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
        end
      end

      def notes(diff)
        if legacy_chart.present?
          return legacy_chart.notes(diff)
        else
          return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
        end
      end

      def max_notes
        return notes(max_diff)
      end

      def exist?(diff)
        exist = level(diff).present?
        if diff == MUSIC_DIFF_UNL
          exist &&= (SiteSettings.pivot_date >= (added_at_unl || SiteSettings.date_low_limit))
        end
        return exist
      end

      def monthly?
        return monthly.present?
      end

      def level_to_s(diff)
        unless exist?(diff)
          return '-'
        else
          return sprintf_for_level(level(diff))
        end
      end

      def notes_to_s(diff)
        unless exist?(diff)
          return '-'
        else
          return sprintf_for_notes(notes(diff))
        end
      end

      def max_diff
        return exist?(MUSIC_DIFF_UNL) ? MUSIC_DIFF_UNL : MUSIC_DIFF_MAS
      end

      def to_hash
        hash = {
          :text_id => text_id, :number => number,
          :title => title, :subtitle => subtitle, :full_title => full_title,
          :monthly => monthly?, :limited => limited, :deleted => deleted
        }
        MUSIC_DIFF_PREFIXES.keys.each do |diff|
          if exist?(diff) and !(diff == MUSIC_DIFF_UNL and unlock_unl == UNLOCK_UNL_TYPE_NEVER)
            hash[MUSIC_DIFF_PREFIXES[diff]] = {
              :level => level_to_s(diff), :notes => notes(diff),
              :has_legacy => exist_legacy?(diff),
            }
          else
            hash[MUSIC_DIFF_PREFIXES[diff]] = {
              :level => nil, :notes => nil,
            }
          end
        end

        return hash
      end

      def <=>(other)
        if number != other.number
          return number <=> other.number
        else
          return sort_key <=> other.sort_key
        end
      end

      def self.get_csv_columns
        columns = [
          {:name => :lookup_key, :unique => true, :dump => true},
          {:name => :text_id,                     :dump => true},
          {:name => :number,                      :dump => true},
          {:name => :title,                       :dump => true},
          {:name => :subtitle,                    :dump => true},
          {:name => :sort_key,                    :dump => true},
          {:name => :jacket,                      :dump => true},
        ]
        MUSIC_DIFF_PREFIXES.keys.each do |diff|
          columns << {:name => "#{MUSIC_DIFF_PREFIXES[diff]}_level".to_sym, :dump => true}
          columns << {:name => "#{MUSIC_DIFF_PREFIXES[diff]}_notes".to_sym, :dump => true}
        end
        columns.concat [
          {:name => :limited,                     :dump => true},
          {:name => :hidden,                      :dump => true},
          {:name => :hidden_type,                 :dump => true},
          {:name => :deleted,                     :dump => true},
          {:name => :display,                     :dump => true},
          {:name => :unlock_unl,                  :dump => true},
          {:name => :appear,                      :dump => true},
          {:name => :category,                    :dump => true},
          {:name => :event,                       :dump => true},
          {:name => :added_at,                    :dump => true},
          {:name => :added_at_unl,                :dump => true},
          {:name => :deleted_at,                  :dump => true},
        ]
        return columns
      end
    end
  end
end
