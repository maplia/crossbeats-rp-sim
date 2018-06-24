require 'cxbrank/const'
require 'cxbrank/master/music'
require 'cxbrank/master/course'
require 'cxbrank/skill'
require 'cxbrank/playdata/music_skill'
require 'cxbrank/playdata/course_skill'

module CxbRank
  module PlayData
    class << self
      def registered app
        app.helpers do
          def skill_list_page(user, edit, skill_options={})
            skill_set = SkillSet.new(user, skill_options)
            skill_set.load!
            fixed_title = "#{user.name}さんの#{PAGE_TITLES[SKILL_LIST_VIEW_URI]}"
            add_template_paths PAGE_TEMPLATE_FILES[SKILL_LIST_VIEW_URI]
            unless edit and session[:user_id]
              data_mtime = skill_set.last_modified
              page_last_modified PAGE_TEMPLATE_FILES[SKILL_LIST_VIEW_URI], data_mtime
            end
            haml :skill_list, :layout => true, :locals => {
              :user => user, :skill_set => skill_set,
              :edit => edit, :ignore_locked => skill_options[:ignore_locked],
              :fixed_title => fixed_title, :tweet => true}
          end

          def music_skill_edit_page(user, &block)
            if params[:text_id]
              session[:text_id] = params[:text_id]
            end
            if !SiteSettings.edit_enabled?
              haml :error, :layout => true, :locals => {:error_no => ERROR_RP_EDIT_DISABLED}
            elsif session[:text_id].blank?
              haml :error, :layout => true, :locals => {:error_no => ERROR_MUSIC_IS_UNDECIDED}
            elsif (music = Master::Music.find_by(:text_id => session[:text_id])).nil?
              haml :error, :layout => true, :locals => {:error_no => ERROR_MUSIC_NOT_EXIST}
            else
              curr_skill = MusicSkill.find_by_user_and_music(user, music)
              temp_skill = MusicSkill.find_by_user_and_music(user, music)
              if params[:text_id]
                session[underscore(temp_skill.class)] = nil
              end
              if session[underscore(temp_skill.class)].present?
                temp_skill.update_by_params!(session[underscore(temp_skill.class)])
              end
              yield curr_skill, temp_skill
            end
          end

          def course_skill_edit_page(user, &block)
            if params[:text_id]
              session[:text_id] = params[:text_id]
            end
            if !SiteSettings.edit_enabled?
              haml :error, :layout => true, :locals => {:error_no => ERROR_RP_EDIT_DISABLED}
            elsif session[:text_id].blank?
              haml :error, :layout => true, :locals => {:error_no => ERROR_COURSE_IS_UNDECIDED}
            elsif (course = Master::Course.find_by(:text_id => session[:text_id])).nil?
              haml :error, :layout => true, :locals => {:error_no => ERROR_COURSE_NOT_EXIST}
            else
              curr_skill = CourseSkill.find_by_user_and_course(user, course)
              temp_skill = CourseSkill.find_by_user_and_course(user, course)
              if params[:text_id]
                session[underscore(temp_skill.class)] = nil
              end
              if session[underscore(temp_skill.class)].present?
                temp_skill.update_by_params!(session[underscore(temp_skill.class)])
              end
              yield curr_skill, temp_skill
            end
          end

          def clear_session_temp_skill(temp_skill)
            session[:text_id] = nil
            session[underscore(temp_skill.class)] = nil
          end
        end

        app.get SKILL_LIST_EDIT_URI do
          private_page do |user|
            skill_list_page user, true, :fill_empty => true
          end
        end

        app.get "#{SKILL_LIST_VIEW_URI}/?:user_id?" do
          public_user_page do |user|
            skill_list_page user, false
          end
        end

        app.get "#{SKILL_LIST_VIEW_IGLOCK_URI}/?:user_id?" do
          public_user_page do |user|
            skill_list_page user, false, :ignore_locked => true
          end
        end

        app.get "#{CLEAR_LIST_VIEW_URI}/?:user_id?" do
          public_user_page do |user|
            skill_chart = Chart.load(user)
            fixed_title = "#{user.name}さんの#{PAGE_TITLES[CLEAR_LIST_VIEW_URI]}"
            data_mtime = skill_chart.last_modified
            add_template_paths PAGE_TEMPLATE_FILES[CLEAR_LIST_VIEW_URI]
            page_last_modified PAGE_TEMPLATE_FILES[CLEAR_LIST_VIEW_URI], data_mtime
            haml :skill_chart, :layout => true, :locals => {
              :user => user, :skill_chart => skill_chart, :fixed_title => fixed_title}
          end
        end

        app.get "#{SKILL_ITEM_EDIT_URI}/?:text_id?" do
          private_page do |user|
            music_skill_edit_page(user) do |curr_skill, temp_skill|
              fixed_title = "#{PAGE_TITLES[SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
              add_template_paths PAGE_TEMPLATE_FILES[SKILL_ITEM_EDIT_URI]
              haml :music_skill_edit, :layout => true, :locals => {
                :user => user,
                :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title}
            end
          end
        end

        app.post SKILL_ITEM_EDIT_URI do
          skill_klass = MusicSkill
          session[underscore(skill_klass)] = Hash[params[underscore(skill_klass)]]
          private_page do |user|
            music_skill_edit_page(user) do |curr_skill, temp_skill|
              unless temp_skill.valid?
                haml :error, :layout => true, :locals => {
                  :errors => temp_skill.errors,
                  :back_uri => SiteSettings.join_site_base(request.path_info)}
              else
                temp_skill.calc!
                method = (params[:update].present? ? 'put' : 'delete')
                fixed_title = "#{PAGE_TITLES[SKILL_ITEM_EDIT_URI]} [#{curr_skill.music.full_title}]"
                add_template_paths PAGE_TEMPLATE_FILES[SKILL_ITEM_EDIT_URI]
                haml :music_skill_edit_conf, :layout => true, :locals => {
                  :user => user,
                  :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title,
                  :method => method}
              end
            end
          end
        end

        app.put SKILL_ITEM_EDIT_URI do
          private_page do |user|
            if params[:y].present?
              music_skill_edit_page(user) do |curr_skill, temp_skill|
                begin
                  temp_skill.calc!
                  temp_skill.save!
                  if SiteSettings.cxb_mode? or !user.point_direct
                    skill_set = SkillSet.new(user)
                    skill_set.load!
                    user.point = skill_set.total_point
                    user.point_direct = false
                    user.point_updated_at = Time.now
                    user.save!
                  end
                  clear_session_temp_skill(temp_skill)
                  redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
                rescue
                  haml :error, :layout => true, :locals => {
                    :error_no => ERROR_DATABASE_SAVE_FAILED,
                    :back_uri => SiteSettings.join_site_base(request.path_info)}
                end
              end
            else
              redirect SiteSettings.join_site_base(SKILL_ITEM_EDIT_URI)
            end
          end
        end

        app.delete SKILL_ITEM_EDIT_URI do
          private_page do |user|
            if params[:y].present?
              music_skill_edit_page(user) do |curr_skill, temp_skill|
                begin
                  temp_skill.destroy
                  skill_set = SkillSet.new(user)
                  skill_set.load!
                  user.point = skill_set.total_point
                  user.point_direct = false
                  user.point_updated_at = Time.now
                  user.save!
                  clear_session_temp_skill(temp_skill)
                  redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
                rescue
                  haml :error, :layout => true, :locals => {
                    :error_no => ERROR_DATABASE_SAVE_FAILED,
                    :back_uri => SiteSettings.join_site_base(request.path_info)}
                end
              end
            else
              redirect SiteSettings.join_site_base(SKILL_ITEM_EDIT_URI)
            end
          end
        end

        app.get "#{SKILL_COURSE_ITEM_EDIT_URI}/?:text_id?" do
          private_page do |user|
            course_skill_edit_page(user) do |curr_skill, temp_skill|
              fixed_title = "#{PAGE_TITLES[SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
              add_template_paths PAGE_TEMPLATE_FILES[SKILL_COURSE_ITEM_EDIT_URI]
              haml :course_skill_edit, :layout => true, :locals => {
                :user => user,
                :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title}
            end
          end
        end

        app.post SKILL_COURSE_ITEM_EDIT_URI do
          skill_klass = CourseSkill
          session[underscore(skill_klass)] = Hash[params[underscore(skill_klass)]]
          private_page do |user|
            course_skill_edit_page(user) do |curr_skill, temp_skill|
              unless temp_skill.valid?
                haml :error, :layout => true, :locals => {
                  :errors => temp_skill.errors,
                  :back_uri => SiteSettings.join_site_base(request.path_info)}
              else
                temp_skill.calc!
                method = (params[:update].present? ? 'put' : 'delete')
                fixed_title = "#{PAGE_TITLES[SKILL_COURSE_ITEM_EDIT_URI]} [#{curr_skill.course.title}]"
                add_template_paths PAGE_TEMPLATE_FILES[SKILL_COURSE_ITEM_EDIT_URI]
                haml :course_skill_edit_conf, :layout => true, :locals => {
                  :user => user,
                  :curr_skill => curr_skill, :temp_skill => temp_skill, :fixed_title => fixed_title,
                  :method => method}
              end
            end
          end
        end

        app.put SKILL_COURSE_ITEM_EDIT_URI do
          private_page do |user|
            if params[:y].present?
              course_skill_edit_page(user) do |curr_skill, temp_skill|
                begin
                  temp_skill.calc!
                  temp_skill.save!
                  skill_set = SkillSet.new(user)
                  skill_set.calc!
                  user.point = skill_set.total_point
                  user.point_direct = false
                  user.point_updated_at = Time.now
                  user.save!
                  clear_session_temp_skill(temp_skill)
                  redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
                rescue
                  haml :error, :layout => true, :locals => {
                    :error_no => ERROR_DATABASE_SAVE_FAILED,
                    :back_uri => SiteSettings.join_site_base(request.path_info)}
                end
              end
            else
              redirect SiteSettings.join_site_base(SKILL_COURSE_ITEM_EDIT_URI)
            end
          end
        end

        app.delete SKILL_COURSE_ITEM_EDIT_URI do
          private_page do |user|
            if params[:y].present?
              course_skill_edit_page(user) do |curr_skill, temp_skill|
                begin
                  temp_skill.destroy
                  skill_set = SkillSet.new(user)
                  skill_set.calc!
                  user.point = skill_set.total_point
                  user.point_direct = false
                  user.point_updated_at = Time.now
                  user.save!
                  clear_session_temp_skill(temp_skill)
                  redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
                rescue
                  haml :error, :layout => true, :locals => {
                    :error_no => ERROR_DATABASE_SAVE_FAILED,
                    :back_uri => SiteSettings.join_site_base(request.path_info)}
                end
              end
            else
              redirect SiteSettings.join_site_base(SKILL_COURSE_ITEM_EDIT_URI)
            end
          end
        end

        app.get "#{MAX_SKILL_VIEW_URI}/?:date?" do
          past_date_page(params[:date]) do |date|
            skill_set = SkillMaxSet.new
            skill_set.load!
            fixed_title = PAGE_TITLES[MAX_SKILL_VIEW_URI]
            if date
              fixed_title << " [#{date.strftime('%Y-%m-%d')}]"
            end
            data_mtime = skill_set.last_modified
            add_template_paths PAGE_TEMPLATE_FILES[MAX_SKILL_VIEW_URI]
            page_last_modified PAGE_TEMPLATE_FILES[MAX_SKILL_VIEW_URI], data_mtime
            haml :skill_list, :layout => true, :locals => {
              :user => nil, :skill_set => skill_set, :edit => false,
              :ignore_locked => false, :fixed_title => fixed_title}
          end
        end

        app.get EXPORT_CSV_URI do
          private_page do |user|
            skills = Skill.find_by_user(user, {:fill_empty => true, :limited => false}).to_a
            if SiteSettings.cxb_mode?
              skills.sort! do |a, b| a.music.number <=> b.music.number end
            else
              skills.sort! do |a, b| a.music.sort_key <=> b.music.sort_key end
            end

            content_type 'text/csv'
            attachment "playdata_#{SiteSettings.cxb_mode? ? 'cxb' : 'rev'}rank_#{user.user_id}.csv"

            bom = %w(EF BB BF).map do |e| e.hex.chr end.join
            CSV.generate(bom) do |csv|
              if SiteSettings.cxb_mode?
                csv << ['Music ID', 'Difficulty', 'Level', 'Name', 'Clear Rate', 'Grade', 'Score', 'Fullcombo', 'Ultimate', 'RP']
              else
                csv << ['Music ID', 'Difficulty', 'Level', 'Name', 'Clear Rate', 'Grade', 'Score', 'Fullcombo', 'Gauge', 'RP']
              end
              skills.each do |skill|
                music = skill.music
                title = music.full_title.gsub(/&#x2661;/, '♡')
                SiteSettings.music_diffs.keys.each do |diff|
                  level = (SiteSettings.cxb_mode? ? music.level(diff) : music.level(diff).to_i)
                  if music.exist?(diff)
                    if skill.stat(diff) == SP_STATUS_NO_PLAY
                      csv << [
                        music.text_id, MUSIC_DIFF_CLASSES[diff].upcase, level, title,
                        nil, nil, nil, nil, nil, nil
                      ]
                    else
                      if SiteSettings.cxb_mode?
                        csv << [
                          music.csv_id,
                          (diff == MUSIC_DIFF_STD ? 'STANDARD' : (diff == MUSIC_DIFF_HRD ? 'HARD' : 'MASTER')),
                          level, title,
                          (skill.rate(diff) || 0).to_i,
                          (skill.stat(diff) == SP_STATUS_FAILED ? 'F' :
                            SP_RANK_STATUSES[skill.rank(diff)].gsub(/&\#x2b;/, '+')),
                          skill.score(diff) || '',
                          (skill.fullcombo?(diff) ? 'yes' : 'no'),
                          (skill.ultimate?(diff) ? 'yes' : 'no'),
                          ((skill.point(diff) || 0)*100).to_i
                        ]
                      else
                        csv << [
                          music.text_id, MUSIC_DIFF_CLASSES[diff].upcase, level, title,
                          ((skill.rate(diff) || 0)*100).to_i,
                          (skill.stat(diff) == SP_STATUS_FAILED ? 'F' :
                            SP_RANK_STATUSES[skill.rank(diff)].gsub(/&\#x2b;/, '+')),
                          skill.score(diff) || '',
                          (skill.fullcombo?(diff) ? 'yes' : 'no'),
                          (skill.ultimate?(diff) ? 'ULT' : (skill.survival?(diff) ? 'SUV' : nil)),
                          ((skill.point(diff) || 0)*100).to_i
                        ]
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
