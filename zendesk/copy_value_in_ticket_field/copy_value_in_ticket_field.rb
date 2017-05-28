#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './CustomTicket.rb'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
custom_tickets = Array.new
modified_ticket_ids = Array.new
error_count = 0
count = 1
data = nil
TARGET_TICKET_FORM_ID = 613727
REA_FROM_FIELD_ID = 79932888
REA_TO_FIELD_ID = 79932908
CUSTOM_TAG = "api_edit_on_propertyid_by_amy_at_zendesk"

# ignore_types = ['subject', 'tickettype', 'description', 'group', 'status', 'assignee', 'priority']

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/tickets.json?page=#{count}")
  c.http_auth_types = :basic
  c.username = EMAIL
  c.password = PASSWORD
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turns json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of tickets
  ticket_list = results["tickets"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  ticket_list.each do |t|

    # only grab non-closed tickets within ticket form ID = 613727
    if t["status"] != "closed"
      if t["ticket_form_id"] == TARGET_TICKET_FORM_ID
        ct = CustomTicket.new t["id"], t["status"], t["tags"], t["ticket_form_id"]

        # find desire value for custom field
        t["custom_fields"].each do |cf|

          # look for value in custom field ID 79503527
          if cf["id"] == REA_FROM_FIELD_ID
            ct.rea_from_field = cf["value"]
          end

        end

        # only push tickets of interest into array i.e.
        # where ticket field for "rea_from_field" isn't empty
        # where custom tag doesn't already exist
        if ( (ct.rea_from_field != nil) && !(ct.tags.include? CUSTOM_TAG) )
          custom_tickets << ct
        end

      end
    end

  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

puts "\nList of ticket IDs that fits the copying requirements:"
custom_tickets.each do |ct|
  puts ct.id
end

# now prompts for user to copy all ticket fields
puts "\n\nare you sure you are ready copy values for #{custom_tickets.count} tickets from ticket field ID 79503527 to ticket field ID79503547? (y/n)"
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort copy of value in custom ticket field by user!!')
end

count = 1

# set up copying
custom_tickets.each do |ct|

  data = "{\"ticket\": {\"tags\":[\"api_edit_on_propertyid_by_amy_at_zendesk\""

  ct.tags.each do |t|
    data << ",\"#{t}\""
  end

  data << "],\"custom_fields\":[{\"id\":\"#{REA_TO_FIELD_ID}\",\"value\":\"#{ct.rea_from_field}\"}]}}"

puts "\n\n#{data}\n\n"

  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/tickets/#{ct.id}.json"
  c.username = EMAIL
  c.password = PASSWORD
  c.url = targeturl
  c.http_put (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with copying value in ticket fields"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
  else
    modified_ticket_ids << results["ticket"]["id"]
  end

  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{modified_ticket_ids.count} ticket fields values copied : #{modified_ticket_ids.inspect}\n"


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
