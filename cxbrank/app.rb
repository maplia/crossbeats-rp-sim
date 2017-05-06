require '../comrank/app'

class CxbRankApp < CxbRank::AppBase
  include CxbRank

  post '/api/authorize' do
    data = JSON.parse(request.body.read, {:symbolize_names => true})
    error_no = User.authenticate(data[:user_id], data[:password])
    jsonx error_no == NO_ERROR
  end

  get '/api/skills/:user_id' do
    user = User.find_by_param_id(params[:user_id])
    last_modified Skill.last_modified(user)
    skills = Skill.find_by_user(user, {:fill_empty => true}).to_a
    skills.sort! do |a, b| a.music.number <=> b.music.number end
    skill_hashes = []
    skills.each do |skill|
      skill_hashes << skill.to_hash
    end
    jsonx skill_hashes
  end

  post '/api/edit' do
    data = JSON.parse(request.body.read, {:symbolize_names => true})
    error_no = User.authenticate(data[:user_id], data[:password])
    if error_no != NO_ERROR
      jsonx false
    else
      begin
        user = User.find_by_param_id(data[:user_id])
        music = Master::Music.find_by(:text_id => data[:text_id])
        skill = Skill.find_by_user_and_music(user, music)
        skill.user_id = user.id
        skill.music = music
        skill.comment = CGI.unescape(data[:body][:comment])
        MUSIC_DIFF_PREFIXES.keys.each do |diff|
          next unless data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym]
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_stat=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:stat])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_point=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:point])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_rate=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:rate])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_rate_f=", false)
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_rank=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:rank])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_combo=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:combo])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_score=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:score])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_gauge=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:gauge])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_locked=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:locked])
          skill.send("#{MUSIC_DIFF_PREFIXES[diff]}_legacy=", data[:body][MUSIC_DIFF_PREFIXES[diff].to_sym][:legacy])
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
    error_no = User.authenticate(data[:user_id], data[:password])
    if error_no != NO_ERROR
      jsonx false
    else
      begin
        user = User.find_by_param_id(data[:user_id])
        skill_set = SkillSet.new(settings.site_mode, user)
        skill_set.load!
        user.point = skill_set.total_point
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
