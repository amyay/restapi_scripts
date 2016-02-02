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
        puts "please provide mapping for ticket form ID #{all_con["value"]}"
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
        puts "please provide mapping for custom ticket field ID #{all_con["field"]}"
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
        puts "please provide mapping for ticket form ID #{any_con["value"]}"
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
        puts "please provide mapping for custom ticket field ID #{any_con["field"]}"
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
        puts "please provide mapping for custom ticket field ID #{a["field"]}"
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
        puts "please provide mapping for group ID #{a["value"]}"
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
        puts "please provide mapping for assignee ID #{a["value"]}"
        user_input = gets.chomp
        assignee_id_hash[a["value"]] = user_input
        a["value"] = user_input
      else
        # group ID mapping already exist in hash
        # just update accordingly
        a["value"] = assignee_id_hash[a["value"]]
      end
    end

    #############################
    ####check for group and assignee ID
    #############################

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


# # now prompts for user to copy all ticket fields
# puts "are you sure you are ready copy these #{specific_custom_ticket_fields.length} custom ticket fields? (y/n)"
# user_input = gets.chomp

# if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
#   abort('abort copy of specific custom ticket fields by user!!')
# end

# count = 1

# # set up copying
# specific_trigger_list.each do |t|

# # puts "type = #{tf.type}, title = #{tf.title}"

#   # skip importing system field
#   next if (!tf.system_field_options.nil?) || (ignore_types.include? tf.type)

#   # set up data depending if it's dropdown or not
#   if tf.type == 'tagger'
#     data = "{\"ticket_field\": {\"type\": \"#{tf.type}\",\"title\" : \"#{tf.title}\",\"description\": \"#{tf.description}\",\"active\": #{tf.active},\"required\": #{tf.required},\"collapsed_for_agents\": #{tf.collapsed_for_agents},\"regexp_for_validation\": #{tf.regexp_for_validation},\"title_in_portal\": \"#{tf.title_in_portal}\",\"visible_in_portal\": #{tf.visible_in_portal},\"editable_in_portal\": #{tf.editable_in_portal},\"required_in_portal\": #{tf.required_in_portal},\"tag\": #{tf.tag},\"removable\": #{tf.removable},\"custom_field_options\": ["
#     # now iterate thru custom field options and add all
#     tf.custom_field_options.each do |cto|
#       data << "{\"name\": \"#{cto['name']}\", \"value\": \"#{cto['value']}\"},"
#     end
#     data.chop!
#     data << "]}}"
#   else
#     data = "{\"ticket_field\": {\"type\": \"#{tf.type}\",\"title\" : \"#{tf.title}\",\"description\": \"#{tf.description}\",\"active\": #{tf.active},\"required\": #{tf.required},\"collapsed_for_agents\": #{tf.collapsed_for_agents},\"regexp_for_validation\": #{tf.regexp_for_validation},\"title_in_portal\": \"#{tf.title_in_portal}\",\"visible_in_portal\": #{tf.visible_in_portal},\"editable_in_portal\": #{tf.editable_in_portal},\"required_in_portal\": #{tf.required_in_portal},\"tag\": #{tf.tag},\"removable\": #{tf.removable}}}\""
#   end

# puts "\n\n#{data}\n\n"

#   targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/ticket_fields.json"
#   c.username = DESTINATION_EMAIL
#   c.password = DESTINATION_PASSWORD
#   c.url = targeturl
#   c.http_post (data)
#   results = JSON.parse (c.body_str)
#   if !results["error"].nil?
#     puts "ERROR: problems with adding custom ticket field"
#     puts "Error description: #{results["error"]}"
#     puts "Error details: #{results["message"]}\n"
#     error_count += 1
#   else
#     created_ticket_field_ids << results["ticket_field"]["id"]
#     created_ticket_field_names << results["ticket_field"]["title"]
#   end

#   count += 1
# #   break if count == 3
# end

# # puts "\n\n***************************************\n#{created_ticket_field_ids.count} custom ticket fields CREATED : #{created_ticket_field_ids.inspect}\n"

# puts "\n\n***************************************\n#{created_ticket_field_ids.count} custom ticket fields CREATED : \n"
# puts " created custom field ID | name of custom field"
# created_ticket_field_ids.zip(created_ticket_field_names).each do |id, name|
#   puts "      #{id}           | #{name}"
# end


# puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
