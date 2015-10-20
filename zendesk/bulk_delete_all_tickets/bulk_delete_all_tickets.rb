#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
ticket_ids = Array.new
ids_join = String.new
count = 1

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
    # add checking condition for xero
    if (t["id"] < 10200)
      ticket_ids << t["id"]
    end
  end

  # prints out list of ticket ID just in case
  puts ticket_ids

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

puts '****************************************************'
puts "total number of tickets to be deleted: #{ticket_ids.length}"
puts '****************************************************'

# now prompts for user to delete all tickets
puts 'are you sure you are ready delete all tickets? (y/n)'
user_input = gets.chomp

if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
  abort('abort ticket deletion by user!!')
end

# set up for deletion
ticket_ids.each_slice(100) do |section_ids|
  # convert array to string join by comma
  ids_join << section_ids.join(',')

  # puts ids_join

  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/tickets/destroy_many.json?ids=#{ids_join}"
  c.url = targeturl
  c.http_delete
  results = JSON.parse (c.body_str)
  if !results["error"].nil?
    puts "ERROR: problems with deletion of tickets"
    puts "Error description: #{results["description"]}"
    puts "Error details: #{results["details"]["base"][0]["description"]}"
    error_count += 1
  end

  # reset ids_join
  ids_join = ""
end
