#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './Trigger.rb'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
trigger_list = Array.new
specific_trigger_list = Array.new
ticket_form_id_hash = Hash.new
custom_field_id_hash = Hash.new
group_id_hash = Hash.new
assignee_id_hash = Hash.new
created_triggers_hash = Hash.new
existing_ticket_field_id_to_name_hash = Hash.new
existing_ticket_form_id_to_name_hash = Hash.new
existing_group_id_to_name_hash = Hash.new
existing_user_id_to_name_hash = Hash.new
error_count = 0
count = 1
data = nil
# ignore_types = ['subject', 'tickettype', 'description', 'group', 'status', 'assignee', 'priority']

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/triggers.json?page=#{count}")
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
  temp_trigger_list = results["triggers"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  temp_trigger_list.each do |t|
    ct = Trigger.new t["id"], t["title"], t["active"], t["actions"], t["conditions"], t["position"]
    trigger_list << ct
  end

  puts trigger_list.inspect

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# print out all triggers
puts ' active? | ID of trigger | name of trigger '
trigger_list.each do |t|
  puts "  #{t.active}   |    #{t.id}   | #{t.title}" if t.active === true
  puts "  #{t.active}  |    #{t.id}   | #{t.title}" if t.active === false
end

puts "\n\n\n"

# now prompts for user to specify the custom fields they want to copy
puts 'please define the list of trigger IDs you would like to copy'
puts 'for example: 12345, 56678'
user_input = gets.chomp

# convert string into array of numbers
user_trigger_ids = user_input.split(/\s*,\s*/).map(&:to_i)

# prints out confirmation
puts "here is a list of triggers you would like to copy"
puts ' ID of trigger | name of trigger '
trigger_list.each do |t|
  if user_trigger_ids.include? t.id
    specific_trigger_list << t
    puts "    #{t.id}   | #{t.title}"
  end
end

puts specific_trigger_list.inspect

############################################################################################
# get the names of each ticket field, and put them in existing_ticket_field_id_to_name_hash
############################################################################################

count = 1

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  targeturl = "https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/ticket_fields.json?page=#{count}"
  c.username = SOURCE_EMAIL
  c.password = SOURCE_PASSWORD
  c.url = targeturl
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
    existing_ticket_field_id_to_name_hash[tf["id"]] = tf["title"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

puts existing_ticket_field_id_to_name_hash.inspect

############################################################################################
# get the names of each ticket form, and put them in existing_ticket_form_id_to_name_hash
############################################################################################
count = 1

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  targeturl = "https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/ticket_forms.json?page=#{count}"
  c.username = SOURCE_EMAIL
  c.password = SOURCE_PASSWORD
  c.url = targeturl
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turns json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of tickets
  ticket_form_list = results["ticket_forms"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  ticket_form_list.each do |tf|
    existing_ticket_form_id_to_name_hash[tf["id"]] = tf["name"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

puts existing_ticket_form_id_to_name_hash.inspect

############################################################################################
# get the names of each group, and put them in existing_group_id_to_name_hash
############################################################################################
count = 1

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  targeturl = "https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/groups.json?page=#{count}"
  c.username = SOURCE_EMAIL
  c.password = SOURCE_PASSWORD
  c.url = targeturl
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turns json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of tickets
  group_list = results["groups"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  group_list.each do |g|
    existing_group_id_to_name_hash[g["id"]] = g["name"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

puts existing_group_id_to_name_hash.inspect

############################################################################################
# get the names of each user, and put them in existing_user_id_to_name_hash
############################################################################################
count = 1

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  targeturl = "https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/users.json?page=#{count}"
  c.username = SOURCE_EMAIL
  c.password = SOURCE_PASSWORD
  c.url = targeturl
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_get
  # puts c.body_str

  # first, turns json into a hash
  results = JSON.parse (c.body_str)

  # now grab an array of tickets
  user_list = results["users"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  user_list.each do |u|
    existing_user_id_to_name_hash[u["id"]] = u["name"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

puts existing_user_id_to_name_hash.inspect


# now checks for ticket form ID and custom field ID mappings
specific_trigger_list.each do |t|

  # check meet all condition
  t.conditions["all"].each do |all_con|

    # 1. check for ticket form IDs
    if all_con["field"] === "ticket_form_id"
      # check existing hash
      if ticket_form_id_hash[all_con["value"]].nil?
        # not present in current hash
        # request for ticket form ID mapping
        puts "please provide mapping for ticket form ID #{all_con["value"]} (#{existing_ticket_form_id_to_name_hash[all_con["value"].to_i]})"
        user_input = gets.chomp
        ticket_form_id_hash[all_con["value"]] = user_input
        all_con["value"] = user_input
      else
        # ticket form ID mapping already exist in hash
        # just update accordingly
        all_con["value"] = ticket_form_id_hash[all_con["value"]]
      end
    end

    # 2. check for custom field IDs
    if all_con["field"].include? "custom_fields_"
      # check existing hash
      if custom_field_id_hash[all_con["field"]].nil?
        # not present in current hash
        # request for custom field ID mapping
        s = all_con["field"].sub(/custom_fields_/, '')
        puts "please provide mapping for #{all_con["field"]} (#{existing_ticket_field_id_to_name_hash[s.to_i]})"
        # puts "please provide mapping for #{all_con["field"]}"
        user_input = gets.chomp
        custom_field_id_hash[all_con["field"]] = 'custom_fields_'+user_input
        all_con["field"] = 'custom_fields_'+user_input
      else
        # custom field ID mapping already exist in hash
        # just update accordingly
        all_con["field"] = custom_field_id_hash[all_con["field"]]
      end
    end
  end

  # check meet any condtition
  t.conditions["any"].each do |any_con|
    # 1. check for ticket form IDs
    if any_con["field"] === "ticket_form_id"
      # check existing hash
      if ticket_form_id_hash[any_con["value"]].nil?
        # not present in current hash
        # request for ticket form ID mapping
        puts "please provide mapping for ticket form ID #{any_con["value"]} (#{existing_ticket_form_id_to_name_hash[any_con["value"].to_i]})"
        user_input = gets.chomp
        ticket_form_id_hash[any_con["value"]] = user_input
        any_con["value"] = user_input
      else
        # ticket form ID mapping already exist in hash
        # just update accordingly
        any_con["value"] = ticket_form_id_hash[any_con["value"]]
      end
    end

    # 2. check for custom field IDs
    if any_con["field"].include? "custom_fields_"
      # check existing hash
      if custom_field_id_hash[any_con["field"]].nil?
        # not present in current hash
        # request for custom field ID mapping
        s = any_con["field"].sub(/custom_fields_/, '')
        puts "please provide mapping for #{any_con["field"]} (#{existing_ticket_field_id_to_name_hash[s.to_i]})"
        # puts "please provide mapping for #{any_con["field"]}"
        user_input = gets.chomp
        custom_field_id_hash[any_con["field"]] = 'custom_fields_'+user_input
        any_con["field"] = 'custom_fields_'+user_input
      else
        # custom field ID mapping already exist in hash
        # just update accordingly
        any_con["field"] = custom_field_id_hash[any_con["field"]]
      end
    end
  end

  # check action
  t.actions.each do |a|

    # check for custom fields
    if a["field"].include? "custom_fields_"
      # check existing hash
      if custom_field_id_hash[a["field"]].nil?
        # not present in current hash
        # request for custom field ID mapping
        s = a["field"].sub(/custom_fields_/, '')
        puts "please provide mapping for #{a["field"]} (#{existing_ticket_field_id_to_name_hash[s.to_i]})"
        # puts "please provide mapping for #{a["field"]}"
        user_input = gets.chomp
        custom_field_id_hash[a["field"]] = 'custom_fields_'+user_input
        a["field"] = 'custom_fields_'+user_input
      else
        # custom field ID mapping already exist in hash
        # just update accordingly
        a["field"] = custom_field_id_hash[a["field"]]
      end
    end

    # check for group_id
    if a["field"] === "group_id"
      # check existing hash
      if group_id_hash[a["value"]].nil?
        # not present in current hash
        # request for group ID mapping
        puts "please provide mapping for group ID #{a["value"]} (#{existing_group_id_to_name_hash[a["value"].to_i]})"
        user_input = gets.chomp
        group_id_hash[a["value"]] = user_input
        a["value"] = user_input
      else
        # group ID mapping already exist in hash
        # just update accordingly
        a["value"] = group_id_hash[a["value"]]
      end
    end

    # check for assignee_id
    if a["field"] === "assignee_id"
      # check existing hash
      if assignee_id_hash[a["value"]].nil?
        # not present in current hash
        # request for assignee ID mapping
        puts "please provide mapping for assignee ID #{a["value"]} (#{existing_user_id_to_name_hash[a["value"].to_i]})"
        user_input = gets.chomp
        assignee_id_hash[a["value"]] = user_input
        a["value"] = user_input
      else
        # group ID mapping already exist in hash
        # just update accordingly
        a["value"] = assignee_id_hash[a["value"]]
      end
    end

  end

end

puts specific_trigger_list.inspect
puts ticket_form_id_hash
puts custom_field_id_hash
puts group_id_hash
puts assignee_id_hash


#################################################
#################################################
#################################################
#################################################
#################################################
#################################################
#################################################


# now prompts for user to copy all ticket fields
puts "are you sure you are ready copy these #{specific_trigger_list.length} triggers? (y/n)"
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort copy of specific custom ticket fields by user!!')
end

count = 1

# set up copying
specific_trigger_list.each do |t|

  data = "{\"trigger\": {\"title\" : \"#{t.title}\",\"active\": #{t.active},\"position\": #{t.position},\"actions\": ["

  # now iterate thru action
  t.actions.each do |a|
    if a['field'].include? 'notification_'
      data << "{\"field\": \"#{a['field']}\", \"value\": #{a['value']}},"
    else
      data << "{\"field\": \"#{a['field']}\", \"value\": \"#{a['value']}\"},"
    end
  end
  data.chop!

  data << "],\"conditions\": {\"all\": ["

  # now iterate thru conditions
  # meet any conditions
  t.conditions["all"].each do |all_con|
    data << "{\"field\": \"#{all_con['field']}\", \"operator\": \"#{all_con['operator']}\", \"value\": \"#{all_con['value']}\"},"
  end

  data.chop! if t.conditions["all"].length > 0
  data << "], \"any\": ["

  # meet all  conditions
  t.conditions["any"].each do |any_con|
    data << "{\"field\": \"#{any_con['field']}\", \"operator\": \"#{any_con['operator']}\", \"value\": \"#{any_con['value']}\"},"
  end

  data.chop! if t.conditions["any"].length > 0
  data << "]}}}"


puts "\n\n#{data}\n\n"

  targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/triggers.json"
  c.username = DESTINATION_EMAIL
  c.password = DESTINATION_PASSWORD
  c.url = targeturl
  c.http_post (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding triggers"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    puts results.inspect
    error_count += 1
  else
    created_triggers_hash[results["trigger"]["title"]] = [t.id, results["trigger"]["id"]]
  end

  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{created_triggers_hash.count} triggers CREATED : \n"
puts " original trigger ID | created trigger ID | name of trigger" if created_triggers_hash.count > 0
created_triggers_hash.each do |name, id_array|
  puts "      #{id_array[0]}       |       #{id_array[1]}     | #{name}"
end


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
