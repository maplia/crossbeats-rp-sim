require 'cxbrank/const'
require 'cxbrank/site_settings'
require 'cxbrank/master/music'
require 'cxbrank/master/music_set'
require 'cxbrank/master/event'

module CxbRank
  module Master
    class << self
      def registered app
        app.get "#{MUSIC_LIST_VIEW_URI}/?:date?" do
          past_date_page(params[:date]) do |date|
            music_set = MusicSet.new
            music_set.load!
            fixed_title = PAGE_TITLES[MUSIC_LIST_VIEW_URI]
            if date
              fixed_title << " [#{date.strftime('%Y-%m-%d')}]"
            end
            data_mtime = music_set.last_modified
            add_template_paths PAGE_TEMPLATE_FILES[MUSIC_LIST_VIEW_URI]
            page_last_modified PAGE_TEMPLATE_FILES[MUSIC_LIST_VIEW_URI], data_mtime
            haml :music_list, :layout => true, :locals => {
              :music_set => music_set, :fixed_title => fixed_title}
          end
        end

        app.get '/api/music/:text_id' do
          music_hash = Music.find_by(:text_id => params[:text_id]).try(:to_hash) || {}
          last_modified Music.last_modified
          jsonx music_hash, params[:callback]
        end

        app.get '/api/musics' do
          music_hashes = Music.find_actives(true).collect do |music| music.to_hash end
          last_modified Music.last_modified
          jsonx music_hashes, params[:callback]
        end

        app.get RANK_CALC_URI do
          music_hashes = Music.find_actives(true).sort.collect do |music| music.to_hash end
          diffs = SiteSettings.music_diffs.keys.sort.collect do |diff| MUSIC_DIFF_PREFIXES[diff] end
          data_mtime = Music.last_modified
          add_template_paths PAGE_TEMPLATE_FILES[RANK_CALC_URI]
          page_last_modified PAGE_TEMPLATE_FILES[RANK_CALC_URI], data_mtime
          haml :calc_rank, :layout => true, :locals => {
            :data => music_hashes, :diffs => diffs}
        end

        app.get RATE_CALC_URI do
          music_hashes = Music.find_actives(true).sort.collect do |music| music.to_hash end
          data_mtime = Music.last_modified
          add_template_paths PAGE_TEMPLATE_FILES[RATE_CALC_URI]
          page_last_modified PAGE_TEMPLATE_FILES[RATE_CALC_URI], data_mtime
          haml :calc_rate, :layout => true, :locals => {
            :data => music_hashes, :diffs => SiteSettings.music_diffs}
        end

        app.get EVENT_SHEET_LIST_URI do
          events = Event.all.order('span_s desc')
          fixed_title = "#{PAGE_TITLES[EVENT_SHEET_LIST_URI]}一覧"
          data_mtime = Event.last_modified
          add_template_paths PAGE_TEMPLATE_FILES[EVENT_SHEET_LIST_URI]
          page_last_modified PAGE_TEMPLATE_FILES[EVENT_SHEET_LIST_URI], data_mtime
          haml :event_list, :layout => true, :locals => {
            :events => events, :fixed_title => fixed_title}
        end

        app.get "#{EVENT_SHEET_VIEW_URI}/:event_text_id?/?:section?" do
          if params[:event_text_id].blank?
            haml :error, :layout => true, :locals => {:error_no => ERROR_EVENT_ID_IS_UNDECIDED}
          elsif !(events = Event.where(:text_id => params[:event_text_id])).exists?
            haml :error, :layout => true, :locals => {:error_no => ERROR_EVENT_ID_NOT_EXIST}
          elsif (event = events.find_by(:section => (params[:section] || 0))).nil?
            haml :error, :layout => true, :locals => {:error_no => ERROR_EVENT_SECTION_NOT_EXIST}
          else
            request.env['X_MOBILE_DEVICE'] = nil
            fixed_title = "#{PAGE_TITLES[EVENT_SHEET_VIEW_URI]} [#{event.title}]"
            data_mtime = event.updated_at
            add_template_paths PAGE_TEMPLATE_FILES[EVENT_SHEET_VIEW_URI]
            page_last_modified PAGE_TEMPLATE_FILES[EVENT_SHEET_VIEW_URI], data_mtime
            haml :event_sheet, :layout => true, :locals => {
              :event => event, :fixed_title => fixed_title}
          end
        end
      end
    end
  end
end
