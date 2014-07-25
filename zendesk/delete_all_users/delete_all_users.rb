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

# now prompts for user to delete all users
puts 'are you sure you are ready delete all users (except account owner)? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort user deletion!!')
end

puts 'what is the user ID of the owner of this zendesk account?'
owner_id = gets.chomp


# iterate for deletion
user_ids.each do |id|
  if id == owner_id.to_i
    puts "owner id #{id} found - not deleted"
    next
  end

  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/users/#{id}.json"
 # puts targeturl
  c.url = targeturl
  c.http_delete
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: cannot delete user ID #{id}"
    puts "Error description: #{results["description"]}"
    puts "Error details: #{results["details"]["base"][0]["description"]}"
    error_count += 1
  end
end
