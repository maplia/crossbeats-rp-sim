#!/usr/local/bin/ruby -Ku

load 'start.rb'

set :run, false
#set :environment, :cgi

STDOUT.binmode
Rack::Handler::CGI.run Sinatra::Application
