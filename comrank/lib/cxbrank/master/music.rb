require 'csv'
require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/master/base'
require 'cxbrank/master/legacy_chart'
require 'cxbrank/master/monthly'
require 'cxbrank/master/format'

module CxbRank
  module Master
    class Music < Base
      include Comparable
      include Master::Format
      has_one :monthly, -> {where 'span_s <= ? and span_e >= ?',
        (SiteSettings.pivot_time || Time.now), (SiteSettings.pivot_time || Time.now)}
      has_many :legacy_charts

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
        if SiteSettings.pivot_date.present? and legacy_charts.present?
          legacy_charts.each do |legacy_chart|
            if (legacy_chart.span_s..(legacy_chart.span_e-1)).include?(SiteSettings.pivot_date)
              return legacy_chart.level(diff)
            end
          end
        end
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_level")
      end

      def legacy_level(diff)
        if legacy_charts.blank?
          return nil
        else
          return legacy_charts[0].level(diff)
        end
      end

      def notes(diff)
        if SiteSettings.pivot_date.present? and legacy_charts.present?
          legacy_charts.each do |legacy_chart|
            if (legacy_chart.span_s..(legacy_chart.span_e-1)).include?(SiteSettings.pivot_date)
              return legacy_chart.notes(diff)
            end
          end
        end
        return send("#{MUSIC_DIFF_PREFIXES[diff]}_notes")
      end

      def legacy_notes(diff)
        if legacy_charts.blank?
          return nil
        else
          return legacy_charts[0].notes(diff)
        end
      end

      def max_notes
        note_data = []
        SiteSettings.music_diffs.keys.each do |diff|
          note_data << (notes(diff) || 0)
        end
        return note_data.max
      end

      def exist?(diff)
        return level(diff).present?
      end

      def exist_legacy?(diff)
        return legacy_level(diff).present?
      end

      def monthly?
        return monthly.present?
      end

      def deleted?
        return deleted && deleted_at <= (SiteSettings.pivot_date || Date.today)
      end

      def level_to_s(diff)
        unless exist?(diff)
          return '-'
        else
          return sprintf_for_level(level(diff))
        end
      end

      def legacy_level_to_s(diff)
        unless exist_legacy?(diff)
          return '-'
        else
          return sprintf_for_level(legacy_level(diff))
        end
      end

      def notes_to_s(diff)
        unless exist?(diff)
          return '-'
        else
          return sprintf_for_notes(notes(diff))
        end
      end

      def legacy_notes_to_s(diff)
        unless exist_legacy?(diff)
          return '-'
        else
          return sprintf_for_notes(legacy_notes(diff))
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

      CSV_COLUMNS = [:lookup_key, :text_id, :number, :title, :subtitle, :sort_key, :jacket]
      MUSIC_DIFF_PREFIXES.keys.sort.each do |diff|
        CSV_COLUMNS.push("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_level".to_sym)
        CSV_COLUMNS.push("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_notes".to_sym)
      end
      CSV_COLUMNS.push(:limited, :hidden, :deleted, :display, :unlock_unl, :added_at,)
      CSV_COLUMNS.push(:appear, :category, :event, :hidden_type, :added_at_unl, :deleted_at)

      def self.restore_from_csv(csv)
        columns = CSV_COLUMNS.dup
        columns.delete(:lookup_key)

        csv.read.each do |row|
          lookup_key = (row.field(:lookup_key) || row.field(:text_id))
          data = self.find_by(:lookup_key => lookup_key)
          unless data
            data = self.new
            data.lookup_key = lookup_key
          end
          columns.each do |column|
            data.send("#{column}=".to_sym, row.field(column))
          end
          data.save!
        end
      end

      def self.dump_to_csv(csv, omit_columns=[])
        output_columns = CSV_COLUMNS - omit_columns
        csv << output_columns

        self.all.each do |music|
          row = CSV::Row.new(output_columns, [])
          output_columns.each do |column|
            row[column] = music.send(column)
          end
          csv << row
        end
      end
    end
  end
end
