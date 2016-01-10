#!/usr/local/bin/ruby -Ku

load './app.rb'

ENV['RACK_ENV'] = YAML.load_file(CxbRank::CONFIG_FILE)['environment']

STDOUT.binmode
Rack::Handler::CGI.run CxbRankApp
