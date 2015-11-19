require 'rubygems'
require 'active_record'
require 'cxbrank/user'

module CxbRank
  class BookmarkletSession < ActiveRecord::Base
    belongs_to :user
  end
end
