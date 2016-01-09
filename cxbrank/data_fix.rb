#!/usr/local/bin/ruby -Ku
$LOAD_PATH << '../comrank/lib'
ENV['GEM_HOME'] = '/home/marines/local/gems/1.8'

require 'digest/md5'
require 'rubygems'
require 'active_record'
require 'cxbrank/const'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/skill'

ActiveRecord::Base.configurations = YAML.load_file(CxbRank::DATABASE_FILE)
ActiveRecord::Base.establish_connection('development')

CxbRank::User.mode = 'cxb'
CxbRank::Music.mode = 'cxb'
CxbRank::Skill.mode = 'cxb'

CxbRank::User.record_timestamps = false
users = CxbRank::User.find(:all)
users.each do |user|
  user.password = Digest::MD5.hexdigest(user.password)
  user.save!
  puts "user_id: #{user.id}"
end

CxbRank::Skill.record_timestamps = false
skills = CxbRank::Skill.find(:all)
skills.each do |skill|
  skill.calc!
  skill.save false
  puts "skill_id: #{skill.id}"
end
