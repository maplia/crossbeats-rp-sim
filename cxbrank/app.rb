require 'csv'
require '../comrank/app'

class CxbRankApp < CxbRank::AppBase
  include CxbRank

  CSV_DIFFS = {
    'STANDARD' => MUSIC_DIFF_STD,
    'HARD'     => MUSIC_DIFF_HRD,
    'MASTER'   => MUSIC_DIFF_MAS,
  }

  get IMPORT_CSV_URI do
    private_page do |user|
      if !SiteSettings.edit_enabled?
        haml :error, :layout => true, :locals => {:error_no => ERROR_RP_EDIT_DISABLED}
      else
        settings.views << SiteSettings.join_comrank_path('views/application')
        musics = Master::Music.find_actives(false)
        haml :import_csv, :layout => true, :locals => {:musics => musics}
      end
    end
  end

  post IMPORT_CSV_URI do
    private_page do |user|
      if params[:datafile]
        SP_RANK_STATUSES[SP_RANK_STATUS_SPP].gsub!(/&#x2b;/, '+')
        invert_rank = SP_RANK_STATUSES.invert
        error_info = {
          :error_no => NO_ERROR, :back_uri => SiteSettings.join_site_base(request.path_info)
        }

        data = params[:datafile][:tempfile].read
        csv = CSV.new(data, headers: true)
        csv.each do |row|
          if (music = Master::Music.find_by_search_key(row['Music ID'])).nil?
            error_info[:error_no] = ERROR_CSV_MUSIC_NOT_EXIST
            error_info[:args] = [row['Music ID']]
            break
          elsif (diff_class = MUSIC_DIFF_PREFIXES[CSV_DIFFS[row['Difficulty']]]).nil?
            error_info[:error_no] = ERROR_CSV_DIFF_NOT_EXIST
            error_info[:args] = [row['Difficulty']]
            break
          else
            begin
              skill = PlayData::MusicSkill.find_by_user_and_music(user, music)
              skill.send("#{diff_class}_stat=", row['Grade'] == 'F' ? SP_STATUS_FAILED : SP_STATUS_CLEAR)
              if row['Grade'] != 'F'
                skill.send("#{diff_class}_point=", BigDecimal.new(sprintf("%.2f", row['RP'].to_i / 100.0)))
                skill.send("#{diff_class}_rate=", row['Clear Rate'].to_i)
                skill.send("#{diff_class}_rate_f=", false)
                skill.send("#{diff_class}_rank=", invert_rank[row['Grade']])
                skill.send("#{diff_class}_combo=", row['Fullcombo'] == 'yes' ? SP_COMBO_STATUS_FC : SP_COMBO_STATUS_NO)
                skill.send("#{diff_class}_gauge=", row['Ultimate'] == 'yes' ? SP_GAUGE_ULTIMATE_CXB : SP_GAUGE_NORMAL)
              end
              skill.send("#{diff_class}_score=", row['Score'].to_i)
              skill.calc!
              skill.save!
            rescue
              error_info[:error_no] = ERROR_DATABASE_SAVE_FAILED
              break
            end
          end
        end
        if error_info[:error_no] == NO_ERROR
          begin
            skill_set = SkillSet.new(user)
            skill_set.load!
            user.point = skill_set.total_point
            user.point_direct = false
            user.point_updated_at = Skill.last_modified(user)
            user.save!
          rescue
            error_info[:error_no] = ERROR_DATABASE_SAVE_FAILED
            break
          end
        end

        if error_info[:error_no] == NO_ERROR
          redirect SiteSettings.join_site_base(SKILL_LIST_EDIT_URI)
        else
          haml :error, :layout => true, :locals => error_info
        end
      end
    end
  end
end
