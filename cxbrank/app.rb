require '../comrank/app'

class CxbRankApp < CxbRank::AppBase
  get '/api/skills/:user_id' do
    user = CxbRank::User.find_by_param_id(sprintf('%05d', params[:user_id].to_i))
    last_modified CxbRank::Skill.last_modified(user)
    skills = CxbRank::Skill.find_by_user(user, {:fill_empty => true})
    skills.sort! do |a, b| a.music.number <=> b.music.number end
    skill_hashes = []
    skills.sort.each do |skill|
      skill_hashes << skill.to_hash
    end
    jsonx skill_hashes, params[:callback]
  end

  post '/edit_direct' do
    data = JSON.parse(request.body.read, {:symbolize_names => true})
    error_no = CxbRank::Authenticator.authenticate({:user_id => data[:user_id], :password => data[:password]})
    if error_no != CxbRank::NO_ERROR
      status 401
    else
      user = CxbRank::User.find_by_param_id(sprintf('%05d', data[:user_id].to_i))
      music = CxbRank::Music.find(:first, :conditions => {:number => data[:number]})
      skill = CxbRank::Skill.find_by_user_and_music(user, music)
      skill.user_id = user.id
      skill.music = music
      skill.comment = data[:skill][:comment]
      CxbRank::MUSIC_DIFF_PREFIXES.keys.each do |diff|
        next unless data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym]
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_stat=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:stat])
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_point=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:point])
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_rate=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:rate])
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_rate_f=", false)
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_rank=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:rank])
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_combo=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:fcs])
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_gauge=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:ultimate])
        skill.send("#{CxbRank::MUSIC_DIFF_PREFIXES[diff]}_locked=", data[:skill][CxbRank::MUSIC_DIFF_PREFIXES[diff].to_sym][:locked])
      end
      skill.calc!
      skill.save!
    end
  end
end
