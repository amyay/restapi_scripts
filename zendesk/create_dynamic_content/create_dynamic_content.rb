#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './Dynamiccontent.rb'
require '../config.rb'

# csv_filename = "my_dc.csv"
csv_filename = "test.csv"
dc_array = Array.new
created_dc_ids = Array.new
data_default = nil
data_variants = nil
count = 1
error_count = 0
current_dc_id = 0

# read input data
CSV.foreach(csv_filename, :headers=>true) do |row|
  dc = Dynamiccontent.new row["Title"],row["Default Locale"],row["Locale 1 Content"],row["Locale 26 Content"],row["Locale 47 Content"],row["Locale 9 Content"],row["Locale 81 Content"],row["Locale 77 Content"],row["Locale 1307 Content"]
  dc_array << dc
end

puts "\n#{dc_array.length} dynamic content found:\n"

dc_array.each do |dc|
  puts dc.name
end


# now prompts for user to copy all ticket fields
puts "\n\nare you sure you are ready create dynamic contents? (y/n)"
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort creating dynamic content by user!!')
end

# now build data for POST command

dc_array.each do |dc|

  # first create default
  data_default = "{\"item\": {\"name\": \"#{dc.name}\",\"default_locale_id\": 1,\"variants\": ["
  data_default << "{\"locale_id\": 1, \"default\": true,\"content\": \"#{dc.variant_1}\"}"
  data_default << "]}}"

  puts "\nDEBUG: data:\n\n#{data_default}\n\n"


  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/dynamic_content/items.json")
  c.http_auth_types = :basic
  c.username = EMAIL
  c.password = PASSWORD
  c.headers['Content-Type'] = "application/json"
  c.verbose = true
  c.http_post (data_default)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding dynamic content"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
    break
  else
    current_dc_id = results["item"]["id"]
    created_dc_ids << current_dc_id
  end

  # now create variants

  data_variants = "{\"variants\": ["
  data_variants << "{\"locale_id\": 26, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_26}\"},"
  data_variants << "{\"locale_id\": 47, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_47}\"},"
  data_variants << "{\"locale_id\": 9, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_9}\"},"
  data_variants << "{\"locale_id\": 81, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_81}\"},"
  data_variants << "{\"locale_id\": 77, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_77}\"},"
  data_variants << "{\"locale_id\": 1307, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_1307}\"}"
  data_variants << "]}"

  puts "\nDEBUG: data:\n\n#{data_variants}\n\n"

  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/dynamic_content/items/#{current_dc_id}/variants/create_many.json"
  c.username = EMAIL
  c.password = PASSWORD
  c.url = targeturl
  c.http_post (data_variants)
  results = JSON.parse (c.body_str)

  if !results["error"].nil?
    puts "ERROR: problems with adding dynamic content variants"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
    break
  end



  count += 1
#   break if count == 3
end

puts "\n\n***************************************\n#{created_dc_ids.count} dynamic content CREATED : #{created_dc_ids.inspect}\n"


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0




# CSV.foreach(csv_filename, :headers=>true) do |row|
#   # groups = row["Groups"].split(/[\s,]+/)
#   groups = row["Groups"].split(/,\s|,/)
#   if orig_agent_group_hash[row["Name"]] != nil
#     puts "***ERROR -- Duplicate User '#{row["Name"]}' in CSV file"
#     next
#   end
#   orig_agent_group_hash[row["Name"]] = groups
# end



# next_page = false
# c = nil
# # source_organizations = Array.new
# # created_organization_ids = Array.new
# error_count = 0
# count = 1
# data = nil


# begin
#   next_page = false
#   # puts "******** count is #{count} *********"
#   # puts "\n"

#   c = Curl::Easy.new ("https://#{SOURCE_SUBDOMAIN}.zendesk.com/api/v2/organizations.json?page=#{count}")
#   c.http_auth_types = :basic
#   c.username = SOURCE_EMAIL
#   c.password = SOURCE_PASSWORD
#   c.headers['Content-Type'] = "application/json"
#   c.verbose = true
#   c.http_get
#   # puts c.body_str

#   # first, turns json into a hash
#   results = JSON.parse (c.body_str)

#   # now grab an array of tickets
#   organization_list = results["organizations"]

#   # within each item in ticket_list, it's a hash, so look for ticket IDs
#   organization_list.each do |o|
#     org = Organization.new o["name"], o["shared_tickets"], o["shared_comments"], o["external_id"], o["domain_names"], o["details"], o["notes"], o["group_id"], o["tags"], o["organization_fields"]
#     source_organizations << org
#   end

#   # check to see if there are more pages to go
#   next_page = !results["next_page"].nil?

#   count += 1

# end while next_page

# # now prompts for user to copy all ticket fields
# puts 'are you sure you are ready copy all organizations? (y/n)'
# user_input = gets.chomp

# if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
#   abort('abort copy of custom ticket fields by user!!')
# end

# count = 1


# # set up copying
# source_organizations.each do |o|

# # puts "type = #{tf.type}, title = #{tf.title}"

#   # skip importing system field
#   # next if (!tf.system_field_options.nil?) || (ignore_types.include? tf.type)

#   # set up data depending if it's dropdown or not
#   data = "{\"organization\": {\"name\": \"#{o.name}\",\"shared_tickets\" : #{o.shared_tickets},\"shared_comments\": \"#{o.shared_comments}\",\"external_id\": #{o.external_id},\"domain_names\": #{o.domain_names},\"details\": #{o.details},\"notes\": #{o.notes},\"group_id\": #{o.group_id},\"tags\": #{o.tags},\"organization_fields\": {"

#   o.organization_fields.each do |key,value|
#     data << "\"#{key}\":"
#     if value.nil?
#       data << 'null,'
#     elsif (value.kind_of? String)
#       tempvalue = value.gsub("\n","\\n")
#       data << "\"#{tempvalue}\","
#     else
#       data << "#{value},"
#     end
#   end

#   data.chop!
#   data << "}}}"

# puts "\n\n#{data}\n\n"

#   targeturl = "https://#{DESTINATION_SUBDOMAIN}.zendesk.com/api/v2/organizations.json"
#   c.username = DESTINATION_EMAIL
#   c.password = DESTINATION_PASSWORD
#   c.url = targeturl
#   c.http_post (data)
#   results = JSON.parse (c.body_str)
#   if !results["error"].nil?
#     puts "ERROR: problems with adding organization"
#     puts "Error description: #{results["error"]}"
#     puts "Error details: #{results["message"]}\n"
#     error_count += 1
#   else
#     created_organization_ids << results["organization"]["id"]
#   end

#   count += 1
# #   break if count == 3
# end

# puts "\n\n***************************************\n#{created_organization_ids.count} organizations CREATED : #{created_organization_ids.inspect}\n"


# puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0
