#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require './Dynamiccontent.rb'
require '../config.rb'

# csv_filename = "my_dc.csv"
# csv_filename = "test.csv"
dc_array = Array.new
created_dc_ids = Array.new
data_default = nil
data_variants = nil
count = 1
error_count = 0
current_dc_id = 0
created_dc_name_id_hash = {}

csv_filename = ARGV.shift

# read input data
CSV.foreach(csv_filename, :headers=>true) do |row|
  dc = Dynamiccontent.new row["Title"],row["Default Locale"],row["Locale 1 Content"],row["Locale 26 Content"],row["Locale 47 Content"],row["Locale 9 Content"],row["Locale 81 Content"],row["Locale 77 Content"],row["Locale 1307 Content"], row["Locale 10 Content"]
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
    current_dc_title = "#{dc.name}"
    current_dc_placeholder = results["item"]["placeholder"]
    created_dc_ids << current_dc_id
    created_dc_name_id_hash[current_dc_title] = [current_dc_id, current_dc_placeholder]
  end


  # now create variants

  data_variants = "{\"variants\": ["
  data_variants << "{\"locale_id\": 26, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_26}\"},"
  data_variants << "{\"locale_id\": 47, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_47}\"},"
  data_variants << "{\"locale_id\": 9, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_9}\"},"
  data_variants << "{\"locale_id\": 81, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_81}\"},"
  data_variants << "{\"locale_id\": 77, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_77}\"},"
  data_variants << "{\"locale_id\": 1307, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_1307}\"},"
  data_variants << "{\"locale_id\": 10, \"active\": true, \"default\": false,\"content\": \"#{dc.variant_10}\"}"
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

puts "\n\n***************************************\n#{created_dc_ids.count} dynamic content CREATED\n"

created_dc_name_id_hash.each do |title, id_placeholder|
  puts "#{id_placeholder[0]}        #{title}                        #{id_placeholder[1]}"
end


puts "\n\n***************************************\n#{error_count} ERRORS DETECTED - please check log for details\n\n" if error_count > 0

