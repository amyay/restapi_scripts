#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# get a list of users in zendesk account

next_page = false
c = nil
organization_ids = Array.new
count = 1


begin

  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"


  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/organizations.json?page=#{count}")
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
  organization_list = results["organizations"]

  # within each item in user_list, it's a hash, so look for user IDs
  organization_list.each do |o|
    organization_ids << o["id"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

if organization_ids.empty?
  abort('no organizations found - aborting deletion...')
else
  puts "organizations to be deleted: #{organization_ids.inspect}"
end

# now prompts for user to copy all ticket fields
puts 'are you sure you are ready delete all organizations? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort deletion of organizations by user!!')
end


# iterate for deletion
organization_ids.each do |id|
  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/organizations/#{id}.json"
  c.url = targeturl
  c.http_delete
  if !c.body_str.lstrip.empty?
    results = JSON.parse (c.body_str)
    if !results["error"].nil?
      puts "ERROR: cannot delete organization ID #{id}"
      puts "Error description: #{results["description"]}"
      puts "Error details: #{results["details"]["base"][0]["description"]}"
      error_count += 1
    end
  end
end

puts "\n\n***************************************\n#{organization_ids.count} organizations DELETED : #{organization_ids.inspect}\n"
