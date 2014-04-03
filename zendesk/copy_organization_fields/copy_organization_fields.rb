#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './OrganizationField.rb'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
organization_fields = Array.new
created_organization_field_ids = Array.new
error_count = 0
count = 1
data = nil


begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/organization_fields.json?page=#{count}")
  c.http_auth_types = :basic
  c.username = SOURCE_EMAIL
  c.password = SOURCE_PASSWORD
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turns json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of tickets
  organization_field_list = results["organization_fields"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  organization_field_list.each do |of|
    orgfield = OrganizationField.new of["type"], of["key"], of["title"], of["description"], of["active"], of["system"], of["regexp_for_validation"], of["custom_field_options"], of["tag"]
    organization_fields << orgfield
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# now prompts for user to copy all ticket fields
puts 'are you sure you are ready copy all organization fieldss? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort copy of organization fields by user!!')
end

count = 1

# puts organization_fields.count
# puts organization_fields.inspect

# set up copying
organization_fields.each do |of|

# set up data depending if it's dropdown or not
  if of.type == 'tagger'
    data = "{\"organization_field\": {\"type\": \"#{of.type}\",\"key\": \"#{of.key}\",\"title\" : \"#{of.title}\",\"description\": \"#{of.description}\",\"active\": #{of.active},\"regexp_for_validation\": #{of.regexp_for_validation},\"custom_field_options\": ["
    # now iterate thru custom field options and add all
    of.custom_field_options.each do |cofo|
      data << "{\"name\": \"#{cofo['name']}\", \"value\": \"#{cofo['value']}\"},"
    end
    data.chop!
    data << "]}}"
  elsif of.type == 'checkbox'
    data = "{\"organization_field\": {\"type\": \"#{of.type}\",\"key\": \"#{of.key}\",\"title\" : \"#{of.title}\",\"description\": \"#{of.description}\",\"active\": #{of.active},\"regexp_for_validation\": #{of.regexp_for_validation},\"tag\": #{of.tag}}}\""

  else
    data = "{\"organization_field\": {\"type\": \"#{of.type}\",\"key\": \"#{of.key}\",\"title\" : \"#{of.title}\",\"description\": \"#{of.description}\",\"active\": #{of.active},\"regexp_for_validation\": #{of.regexp_for_validation}}}\""
  end
puts "\n\n#{data}\n\n"

  targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/organization_fields.json"
  c.username = DESTINATION_EMAIL
  c.password = DESTINATION_PASSWORD
  c.url = targeturl
  c.http_post (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding organization field"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
  else
    created_organization_field_ids << results["organization_field"]["id"]
  end

  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{created_organization_field_ids.count} organization fields CREATED : #{created_organization_field_ids.inspect}\n"


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
