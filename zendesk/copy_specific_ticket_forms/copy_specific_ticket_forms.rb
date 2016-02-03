#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './TicketForm.rb'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
ticket_form_list = Array.new
specific_ticket_form_list = Array.new
ticket_field_id_hash = Hash.new
new_ticket_field_ids = Array.new
created_ticket_form_hash = Hash.new
error_count = 0
count = 1
data = nil
# ignore_types = ['subject', 'tickettype', 'description', 'group', 'status', 'assignee', 'priority']

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/ticket_forms.json?page=#{count}")
  c.http_auth_types = :basic
  c.username = SOURCE_EMAIL
  c.password = SOURCE_PASSWORD
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turns json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of triggers
  temp_ticket_form_list = results["ticket_forms"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  temp_ticket_form_list.each do |t|
    t = TicketForm.new t["id"], t["name"], t["raw_name"], t["display_name"], t["raw_display_name"], t["end_user_visible"], t["position"], t["ticket_field_ids"], t["active"], t["default"], t["in_all_brands"], t["restricted_brand_ids"]
    ticket_form_list << t
  end

  puts ticket_form_list.inspect

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# print out all ticket forms
puts ' active? | ID of ticket form | name of ticket form '
ticket_form_list.each do |t|
  puts "  #{t.active}   |       #{t.id}      | #{t.name}" if t.active === true
  puts "  #{t.active}  |       #{t.id}      | #{t.name}" if t.active === false
end

puts "\n\n\n"

# now prompts for user to specify the ticket forms they want to copy
puts 'please define the list of ticket form IDs you would like to copy'
puts 'for example: 12345, 56678'
user_input = gets.chomp

# convert string into array of numbers
user_ticket_form_ids = user_input.split(/\s*,\s*/).map(&:to_i)

# prints out confirmation
puts "here is a list of ticket forms you would like to copy"
puts ' ID of ticket form | name of ticket form '
ticket_form_list.each do |t|
  if user_ticket_form_ids.include? t.id
    specific_ticket_form_list << t
    puts "       #{t.id}      | #{t.name}"
  end
end

puts "current specific_ticket_form_list"
puts specific_ticket_form_list.inspect

# now checks for ticket form ID and ticket field ID mappings
specific_ticket_form_list.each do |t|

  # check thru each ticket field ID
  t.ticket_field_ids.each_with_index do |tfid, index|

    # first 5 elements are default and cannot be removed / reordered
    # subject, description, status, group, assignee
    # let's grap IDs for them, in case things can change in the future (so they are not default and unmovable)

    if ticket_field_id_hash[tfid].nil?
      # not present in current hash
      # request for custom field ID mapping
      puts "please provide mapping for ticket field ID #{tfid} (subject?)" if index == 0
      puts "please provide mapping for ticket field ID #{tfid} (description?)" if index == 1
      puts "please provide mapping for ticket field ID #{tfid} (status?)" if index == 2
      puts "please provide mapping for ticket field ID #{tfid}" if index > 2
      user_input = gets.chomp
      ticket_field_id_hash[tfid] = user_input.to_i
      new_ticket_field_ids[index] = user_input.to_i
    else
      # custom field ID mapping already exist in hash
      # just update accordingly
      new_ticket_field_ids[index] = ticket_field_id_hash[tfid]
    end
  end
  # update ticket_field_ids
  t.ticket_field_ids = new_ticket_field_ids
end

puts "current specific_ticket_form_list"
puts specific_ticket_form_list.inspect

puts "\ncurrent ticket_field_id_hash"
puts ticket_field_id_hash

# now prompts for user to ticket forms
puts "are you sure you are ready copy these #{specific_ticket_form_list.length} ticket forms? (y/n)"
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort copy of specific ticket forms by user!!')
end

count = 1

# set up copying
specific_ticket_form_list.each do |t|

  data = "{\"ticket_form\": {\"name\" : \"#{t.name}\",\"raw_name\": \"#{t.raw_name}\", \"display_name\": \"#{t.display_name}\", \"raw_display_name\": \"#{t.raw_display_name}\", \"end_user_visible\": #{t.end_user_visible}, \"position\": #{t.position}, \"active\": #{t.active}, \"default\": #{t.default}, \"ticket_field_ids\": ["

  # now iterate thru action
  t.ticket_field_ids.each do |tfid|
    data << "#{tfid},"
  end
  data.chop!
  data << "]}}"

puts "\n\n#{data}\n\n"

  targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/ticket_forms.json"
  c.username = DESTINATION_EMAIL
  c.password = DESTINATION_PASSWORD
  c.url = targeturl
  c.http_post (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding ticket forms"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    puts results.inspect
    error_count += 1
  else
    created_ticket_form_hash[results["ticket_form"]["name"]] = [t.id, results["ticket_form"]["id"]]
  end

  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{created_ticket_form_hash.count} ticket forms CREATED : \n"
puts " original ticket form ID | created ticket form ID | name of ticket form" if created_ticket_form_hash.count > 0
created_ticket_form_hash.each do |name, id_array|
  puts "          #{id_array[0]}         |         #{id_array[1]}         | #{name}"
end


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
