#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './CustomTicketField.rb'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
custom_ticket_fields = Array.new
created_ticket_field_ids = Array.new
error_count = 0
count = 1
data = nil
ignore_types = ['subject', 'tickettype', 'description', 'group', 'status', 'assignee', 'priority']

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/ticket_fields.json?page=#{count}")
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
  ticket_field_list = results["ticket_fields"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  ticket_field_list.each do |tf|
    ctf = CustomTicketField.new tf["type"], tf["title"], tf["description"], tf["active"], tf["required"], tf["collapsed_for_agents"], tf["regexp_for_validation"], tf["title_in_portal"], tf["visible_in_portal"], tf["editable_in_portal"], tf["required_in_portal"], tf["tag"], tf["removable"], tf["system_field_options"], tf["custom_field_options"]
    custom_ticket_fields << ctf
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# now prompts for user to copy all ticket fields
puts 'are you sure you are ready copy all custom ticket fields? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort copy of custom ticket fields by user!!')
end

count = 1

# set up copying
custom_ticket_fields.each do |tf|

# puts "type = #{tf.type}, title = #{tf.title}"

  # skip importing system field
  next if (!tf.system_field_options.nil?) || (ignore_types.include? tf.type)

  # set up data depending if it's dropdown or not
  if tf.type == 'tagger'
    data = "{\"ticket_field\": {\"type\": \"#{tf.type}\",\"title\" : \"#{tf.title}\",\"description\": \"#{tf.description}\",\"active\": #{tf.active},\"required\": #{tf.required},\"collapsed_for_agents\": #{tf.collapsed_for_agents},\"regexp_for_validation\": #{tf.regexp_for_validation},\"title_in_portal\": \"#{tf.title_in_portal}\",\"visible_in_portal\": #{tf.visible_in_portal},\"editable_in_portal\": #{tf.editable_in_portal},\"required_in_portal\": #{tf.required_in_portal},\"tag\": #{tf.tag},\"removable\": #{tf.removable},\"custom_field_options\": ["
    # now iterate thru custom field options and add all
    tf.custom_field_options.each do |cto|
      data << "{\"name\": \"#{cto['name']}\", \"value\": \"#{cto['value']}\"},"
    end
    data.chop!
    data << "]}}"
  else
    data = "{\"ticket_field\": {\"type\": \"#{tf.type}\",\"title\" : \"#{tf.title}\",\"description\": \"#{tf.description}\",\"active\": #{tf.active},\"required\": #{tf.required},\"collapsed_for_agents\": #{tf.collapsed_for_agents},\"regexp_for_validation\": #{tf.regexp_for_validation},\"title_in_portal\": \"#{tf.title_in_portal}\",\"visible_in_portal\": #{tf.visible_in_portal},\"editable_in_portal\": #{tf.editable_in_portal},\"required_in_portal\": #{tf.required_in_portal},\"tag\": #{tf.tag},\"removable\": #{tf.removable}}}\""
  end

puts "\n\n#{data}\n\n"

  targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/ticket_fields.json"
  c.username = DESTINATION_EMAIL
  c.password = DESTINATION_PASSWORD
  c.url = targeturl
  c.http_post (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding custom ticket field"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
  else
    created_ticket_field_ids << results["ticket_field"]["id"]
  end

  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{created_ticket_field_ids.count} custom ticket fields CREATED : #{created_ticket_field_ids.inspect}\n"


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
