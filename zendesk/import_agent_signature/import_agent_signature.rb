#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

useremail = "amy@zendesk.com"

c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/users/search.json?query=%22#{useremail}%22")
c.http_auth_types = :basic
c.username = EMAIL
c.password = PASSWORD
c.headers['Content-Type'] = "application/json"
c.verbose = true
c.http_get
puts c.body_str

userid = c.body_str.match(/{\"users\":\[\{\"id\":([^\/.]*),/)[1]

# just to get rid of colour coding error on sublime"

# puts "user id = " + userid

targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/users/#{userid}.json"
data = '{"user":{"signature":"script file signature 03\rthis is a new line\r\r\rthis is another line after some empty carriage return!"}}'

c.url = targeturl
c.http_put (data)



# outfile_signature = File.open('./output/signature.txt', "wb")
# outfile_signature << "curl -u amy.tester.a001@gmail.com:testmen0w -v -H \"Content-Type: application/json\" -X PUT https://trial.zendesk.com/api/v2/users/"+userid+".json -d'"
# outfile_signature << "{ \"user\":{\"signature\":\"something\""
# outfile_signature << "\n"

# outfile_signature << "}}'"


# Dump current User database
# User.dump_storage
# outfile_signature.close
