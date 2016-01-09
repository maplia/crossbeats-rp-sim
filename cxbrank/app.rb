require '../comrank/app'

class CxbRankApp < CxbRank::AppBase
  post '/api/authorize' do
    data = JSON.parse(request.body.read, {:symbolize_names => true})
    error_no = CxbRank::Authenticator.authenticate({:user_id => data[:user_id], :password => data[:password]})
    jsonx error_no == CxbRank::NO_ERROR
  end

  get '/api/skills/:user_id' do
    user = CxbRank::User.find_by_param_id(params[:user_id])
    last_modified CxbRank::Skill.last_modified(user)
    skills = CxbRank::Skill.find_by_user(user, {:fill_empty => true})
    skills.sort! do |a, b| a.music.number <=> b.music.number end
    skill_hashes = []
    skills.each do |skill|
      skill_hashes << skill.to_hash
    end
    jsonx skill_hashes
  end

  post '/api/edit' do
    data = JSON.parse(request.body.read, {:symbolize_names => true})
    error_no = CxbRank::Authenticator.authenticate({:user_id => data[:user_id], :password => data[:password]})
    if error_no != CxbRank::NO_ERROR
      jsonx false
    else
      begin
        user = CxbRank::User.find_by_param_id(data[:user_id])
        music = CxbRank::Music.find(:first, :conditions => {:text_id => data[:text_id]})
        skill = CxbRank::Skill.find_by_user_and_music(user, music)
        skill.user_id = user.id
        skill.music = music
        skill.comment = data[:body][:comment]
        CxbRank::MUSIC_DIFF_PREFIXES.keys.each do |diff|
          next unless data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym]
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_stat=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:stat])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_point=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:point])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_rate=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:rate])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_rate_f=", false)
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_rank=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:rank])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_combo=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:combo])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_gauge=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:gauge])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_locked=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:locked])
          skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_legacy=", data[:body][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:legacy])
        end
        skill.calc!
        skill.save!
        jsonx true
      rescue
        jsonx false
      end
    end
  end

  post '/api/edit_fix' do
    data = JSON.parse(request.body.read, {:symbolize_names => true})
    error_no = CxbRank::Authenticator.authenticate({:user_id => data[:user_id], :password => data[:password]})
    if error_no != CxbRank::NO_ERROR
      jsonx false
    else
      begin
        user = CxbRank::User.find_by_param_id(data[:user_id])
        user.point = CxbRank::SkillSet.load(settings.site_mode, user).total_point
        user.point_direct = false
        user.point_updated_at = Time.now
        user.save!
        jsonx true
      rescue
        jsonx false
      end
    end
  end
end
