#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# get a list of users in zendesk account

next_page = false
c = nil
user_ids = Array.new
count = 1

begin

  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"


  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/users.json?page=#{count}")
  c.http_auth_types = :basic
  c.username = EMAIL
  c.password = PASSWORD
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turn json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of users
  user_list = results["users"]

  # within each item in user_list, it's a hash, so look for user IDs
  user_list.each do |u|
    user_ids << u["id"]
  end

  # grab all user IDs
  # user_ids = c.body_str.scan(/(?<=\"id\":)\w+/)

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# puts user_ids
# puts user_ids.count

# iterate for deletion
# user_ids.each do |id|
#   targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/users/#{id}.json"
#  # puts targeturl
#   c.url = targeturl
#   c.http_delete
#   results = JSON.parse (c.body_str)
#   if !results["error"].nil?
#     puts "ERROR: cannot delete user ID #{id}"
#     puts "Error description: #{results["description"]}"
#     puts "Error details: #{results["details"]["base"][0]["description"]}"
#     error_count += 1
#   end
# end
