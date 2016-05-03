#!/usr/local/bin/ruby -Ku

load './../common/app.rb'

STDOUT.binmode
Rack::Handler::CGI.run RevRankApp
