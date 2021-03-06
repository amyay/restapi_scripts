#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# get a list of users in zendesk account

next_page = false
c = nil
organization_field_ids = Array.new
count = 1


begin

  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"


  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/organization_fields.json?page=#{count}")
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
  organization_field_list = results["organization_fields"]

  # within each item in user_list, it's a hash, so look for user IDs
  organization_field_list.each do |of|
    organization_field_ids << of["id"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

if organization_field_ids.empty?
  abort('no organization fields found - aborting deletion...')
else
  puts "organization fields to be deleted: #{organization_field_ids.inspect}"
end

# now prompts for user to copy all ticket fields
puts 'are you sure you are ready delete all organization fields? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort deletion of organization fields by user!!')
end


# iterate for deletion
organization_field_ids.each do |id|
  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/organization_fields/#{id}.json"
  c.url = targeturl
  c.http_delete
  if !c.body_str.lstrip.empty?
    results = JSON.parse (c.body_str)
    if !results["error"].nil?
      puts "ERROR: cannot delete organization field ID #{id}"
      puts "Error description: #{results["description"]}"
      puts "Error details: #{results["details"]["base"][0]["description"]}"
      error_count += 1
    end
  end
end

puts "\n\n***************************************\n#{organization_field_ids.count} organization fields DELETED : #{organization_field_ids.inspect}\n"
