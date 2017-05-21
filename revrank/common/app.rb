$LOAD_PATH << '../../comrank/lib'
require '../../comrank/app'
require 'json'
require 'cxbrank/const'
require 'cxbrank/master/music'
require 'cxbrank/master/course'
require 'cxbrank/playdata/music_skill'
require 'cxbrank/playdata/course_skill'
require 'cxbrank/bookmarklet'

class RevRankApp < CxbRank::AppBase
  include CxbRank
  helpers do
    def valid_referrer?
      return (request.referrer || '').include?(settings.mydata_host)
    end

    def bookmarklet_session(&block)
      if !valid_referrer?
        jsonx :status => 401, :message => 'MY PAGEからのアクセスではありません'
      elsif (data = JSON.parse(request.body.read, {:symbolize_names => true}))[:key].blank?
        jsonx :status => 401, :message => 'セッションキーが指定されていません'
      elsif (session = BookmarkletSession.find_by(:key => data[:key])).nil?
        jsonx :status => 401, :message => 'セッションキーが間違っています'
      else
        begin
          session.edit_count += 1
          session.save!
          yield session, data
        rescue
          jsonx :status => 400, :message => $!.message
        end
      end
    end
  end

  post '/bml_login' do
    if !valid_referrer?
      jsonx :status => 401, :message => 'MY PAGEからのアクセスではありません'
    elsif (error_no = CxbRank::BookmarkletAuthenticator.authenticate(params)) != CxbRank::NO_ERROR
      jsonx :status => 401, :message => CxbRank::ERRORS[error_no]
    else
      session = CxbRank::BookmarkletSession.new
      session.user = CxbRank::User.find_by_param_id(params[:game_id])
      session.key = SecureRandom.hex(32)
      begin
        session.save!
        jsonx :status => 200, :key => session.key, :user_id => session.user.user_id
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_update_master' do
    bookmarklet_session do |session, data|
      begin
        case data[:type]
        when 'music'
          item = Master::Music.create_by_request(data[:body])
          item.save!
        when 'course'
          item = Master::Course.create_by_request(data[:body])
          item.save!
        else
          jsonx :status => 400, :message => "TypeError: #{data[:type]}"
        end
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_edit' do
    bookmarklet_session do |session, data|
      begin
        case data[:type]
        when 'music'
          if (music = Master::Music.find_by(:lookup_key => data[:lookup_key])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          elsif (skill = PlayData::MusicSkill.create_by_request(session.user, music, data[:body])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          else
            skill.save!
          end
        when 'course'
          if (course = Master::Course.find_by(:lookup_key => data[:lookup_key])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          elsif (skill = PlayData::CourseSkill.create_by_request(session.user, course, data[:body])).nil?
            jsonx :status => 400, :message => "Lookup_key [#{data[:lookup_key]}] is not found"
          else
            skill.save!
          end
        else
          jsonx :status => 400, :message => "TypeError: #{data[:type]}"
        end
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_point' do
    bookmarklet_session do |session, data|
      begin
        session.user.point = data[:body][:point]
        session.user.point_direct = true
        session.user.point_updated_at = Time.now
        session.user.save!
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end

  post '/bml_logout' do
    bookmarklet_session do |session, data|
      begin
        session.destroy
      rescue
        status 500
        jsonx :message => $!.message
      end
    end
  end
end
