#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# get a list of groups in zendesk account

next_page = false
# c = nil
# source_organizations = Array.new
# created_organization_ids = Array.new
error_count = 0
count = 1
data = nil

csv_filename = "agent_group_test.csv"

group_hash = {}
user_hash = {}
orig_agent_group_hash = {}
mod_agent_group_hash = {}


begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/groups.json?page=#{count}")
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
  group_list = results["groups"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  group_list.each do |g|
    group_name = g["name"]
    group_id = g["id"]
    group_hash[group_name] = group_id
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# check group_hash
puts group_hash
puts group_hash.length


# get a list of agents in zendesk account
count = 1

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/users.json?page=#{count}&role[]=agent&role[]=admin")
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
  user_list = results["users"]

  # within each item in ticket_list, it's a hash, so look for ticket IDs
  user_list.each do |u|
    user_name = u["name"]
    user_id = u["id"]
    user_hash[user_name] = user_id
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# check group_hash
puts user_hash
puts user_hash.length


# now read input file for agent_group mapping, and put that in a hash
# {"user name" ==> ["group1", "group2", "group3"]}

CSV.foreach(csv_filename, :headers=>true) do |row|
  # groups = row["Groups"].split(/[\s,]+/)
  groups = row["Groups"].split(/,\s|,/)
  orig_agent_group_hash[row["Name"]] = groups
end

# check output
puts orig_agent_group_hash

# now recreate the same hash, but use user and group ID instead
orig_agent_group_hash.each do |a_name, a_groups|

  group_ids = []

  # puts "DEBUG: a_name = #{a_name}, a_group = #{a_groups}"
  user_id = user_hash[a_name]

  if user_id == nil
    puts "ERROR -- User '#{a_name}' does not have a valid user ID"
    next
  end

  # puts "DEBUG: user_id = #{user_id}"

  a_groups.each do |g|

    # puts "DEBUG: g = #{g}"
    if group_hash[g] == nil
      puts "ERROR -- Group '#{g}' does not have a valid group ID"
      next
    end
    group_ids << group_hash[g]
    # puts "DEBUG: group_ids = #{group_ids}"
  end
  mod_agent_group_hash[user_id] = group_ids
end


# check output
puts mod_agent_group_hash

# now build data for POST command

data = "{\"group_memberships\": ["

mod_agent_group_hash.each do |a_user_id, a_group_ids|
  a_group_ids.each do |group_id|
    data << "{\"user_id\": #{a_user_id}, \"group_id\": #{group_id}},"
  end
end

data.chop!
data << ']}'
puts data


# now prompts for user to copy all ticket fields
puts 'are you sure you are ready update agents group membership? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort group membership update by user!!')
end


targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/group_memberships/create_many.json"
  c.username = EMAIL
  c.password = PASSWORD
  c.url = targeturl
  c.http_post (data)
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with adding groups to users"
    puts "Error description: #{results["error"]}"
    puts "Error details: #{results["message"]}\n"
    error_count += 1
  end



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
