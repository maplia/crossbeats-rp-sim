require 'cxbrank/const'
require 'cxbrank/user'
require 'cxbrank/music'
require 'cxbrank/course'

module CxbRank
	module UserIdValidator
		def validate_user_id(user_id)
			unless user_id
				return ERROR_USERID_IS_UNINPUTED
			end
			unless user_id.size == USER_ID_FIGURE
				return ERROR_USERID_IS_UNREGISTERED
			end
			unless User.exists?(user_id.to_i)
				return ERROR_USERID_IS_UNREGISTERED
			end

			return NO_ERROR
		end
  end

	module MusicTextIdValidator
		def validate_music_text_id(text_id)
			unless text_id
				return ERROR_MUSIC_IS_UNDECIDED
			end
			unless Music.exists?({:text_id => text_id})
				return ERROR_MUSIC_NOT_EXIST
			end

			return NO_ERROR
		end
	end

	module CourseTextIdValidator
		def validate_course_text_id(text_id)
			unless text_id
				return ERROR_COURSE_IS_UNDECIDED
			end
			unless Course.exists?({:text_id => text_id})
				return ERROR_COURSE_NOT_EXIST
			end

			return NO_ERROR
		end
	end
end
