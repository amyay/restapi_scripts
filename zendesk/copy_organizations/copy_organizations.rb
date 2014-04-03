#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './Organization.rb'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
source_organizations = Array.new
created_organization_ids = Array.new
error_count = 0
count = 1
data = nil


begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/organizations.json?page=#{count}")
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
  organization_list = results["organizations"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  organization_list.each do |o|
    org = Organization.new o["name"], o["shared_tickets"], o["shared_comments"], o["external_id"], o["domain_names"], o["details"], o["notes"], o["group_id"], o["tags"], o["organization_fields"]
    source_organizations << org
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# now prompts for user to copy all ticket fields
puts 'are you sure you are ready copy all organizations? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort copy of custom ticket fields by user!!')
end

count = 1


# set up copying
source_organizations.each do |o|

# puts "type = #{tf.type}, title = #{tf.title}"

  # skip importing system field
  # next if (!tf.system_field_options.nil?) || (ignore_types.include? tf.type)

  # set up data depending if it's dropdown or not
  data = "{\"organization\": {\"name\": \"#{o.name}\",\"shared_tickets\" : #{o.shared_tickets},\"shared_comments\": \"#{o.shared_comments}\",\"external_id\": #{o.external_id},\"domain_names\": #{o.domain_names},\"details\": #{o.details},\"notes\": #{o.notes},\"group_id\": #{o.group_id},\"tags\": #{o.tags},\"organization_fields\": {"

  o.organization_fields.each do |key,value|
    data << "\"#{key}\":"
    if value.nil?
      data << 'null,'
    elsif (value.kind_of? String)
      tempvalue = value.gsub("\n","\\n")
      data << "\"#{tempvalue}\","
    else
      data << "#{value},"
    end
  end

  data.chop!
  data << "}}}"

puts "\n\n#{data}\n\n"

  targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/organizations.json"
  c.username = DESTINATION_EMAIL
  c.password = DESTINATION_PASSWORD
  c.url = targeturl
  c.http_post (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding organization"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
  else
    created_organization_ids << results["organization"]["id"]
  end

  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{created_organization_ids.count} organizations CREATED : #{created_organization_ids.inspect}\n"


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
