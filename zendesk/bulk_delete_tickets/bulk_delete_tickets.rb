#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# test to make sure we can connect to Zendesk account

c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/users/me.json")
c.http_auth_types = :basic
c.username = EMAIL
c.password = PASSWORD
c.headers['Content-Type'] = "application/json"
c.verbose = true
c.http_get
puts c.body_str

# ids_array = [40, 41, 42, 43, 44]
ids_array = [56, 57, 58]
ids_join = ids_array.join(',')


targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/tickets/destroy_many.json?ids=#{ids_join}"

c.url = targeturl
c.http_delete
results = JSON.parse (c.body_str)
if !results["error"].nil?
  puts "ERROR: cannot delete tickets ID #{id}"
  puts "Error description: #{results["description"]}"
  puts "Error details: #{results["details"]["base"][0]["description"]}"
  error_count += 1
end

