#!/usr/local/bin/ruby -Ku

load './app.rb'

STDOUT.binmode
Rack::Handler::CGI.run RevRankApp
