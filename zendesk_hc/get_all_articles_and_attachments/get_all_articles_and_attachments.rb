#!/usr/bin/env ruby

require 'csv'
require 'curb'
require 'json'
require '../config.rb'

# get a list of tickets in zendesk account

next_page = false
c = nil
article_ids = Array.new
# ids_join = String.new
count = 1
error_count = 0

# first get a list of article IDs in Zendesk

begin
  next_page = false
  # puts "******** count is #{count} *********"
  # puts "\n"

  c = Curl::Easy.new ("https://#{SUBDOMAIN}.zendesk.com/api/v2/help_center/articles.json?page=#{count}")
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
  article_list = results["articles"]

  # within each item in active_trigger_list, it's a hash, so look for trigger IDs
  article_list.each do |a|
    article_ids << a["id"]
  end

  # check to see if there are more pages to go
  next_page = !results["next_page"].nil?

  count += 1

end while next_page

# puts article_ids
# puts article_ids.count

# now, iterate thru the array and grab each individual article, as well as its attachments
article_ids.each do |id|
  # find out the number of translations available for this article
  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/help_center/articles/#{id}/translations.json"
  c.url = targeturl
  c.http_get
  results = JSON.parse (c.body_str)

  translation_list = results["translations"]
  locale_list = Array.new

  # now grab individual article
  targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/help_center/articles/#{id}/translations.json"
  c.http_get
  results = JSON.parse (c.body_str)
  # create an output file
  outfile = File.open("./output/#{id}.json", "wb")
  outfile << results
  outfile.close

  # get comment for each individual article

  # go thru each translation and get the locale
  # translation_list.each do |t|
  #   locale_list << t["locale"]
  # end

  # now for each local, get individual article body
  # locale_list.each do |locale|
  #   targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/help_center/articles/#{id}/translations/#{locale}.json"
  #   c.http_get
  #   results = JSON.parse (c.body_str)
  #   # create an output file
  #   outfile = File.open("./output/#{id}-#{locale}.json", "wb")
  #   outfile << results
  #   outfile.close
  # end
end




# # setting up data to deactivate triggers
# data = '{"trigger":{"active": false}}'

# # prompts user before deactivating all triggers
# puts 'are you sure you are ready to deactivate all triggers? (y/n)'
# user_input = gets.chomp

# if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
#   abort('abort trigger deactivation by user!!')
# end

# # iterate for deactivation
# active_trigger_ids.each do |id|
#   targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/triggers/#{id}.json"
#   # puts targeturl
#   c.url = targeturl
#   c.http_put (data)
#   results = JSON.parse (c.body_str)
#   if !results["error"].nil?
#     puts "ERROR: cannot deactivate trigger ID #{id}"
#     puts "Error description: #{results["description"]}"
#     puts "Error details: #{results["details"]["base"][0]["description"]}"
#     error_count += 1
#   end
# end

# puts "deactivated the following #{active_trigger_ids.count} triggers: #{active_trigger_ids.join(',')}"

# puts 'errors detected - please check log for details' if error_count > 0

# # setting up data to reactivate triggers
# data = '{"trigger":{"active": true}}'

# # now prompts for user to reactivate all triggers
# puts 'are you sure you are ready to reactivate all triggers? (y/n)'
# user_input = gets.chomp

# if !(user_input.downcase == 'y' || user_input.downcase == 'yes')
#   abort('abort trigger activation by user!!')
# end

# # iterate for reactivation
# active_trigger_ids.each do |id|
#   targeturl = "https://#{SUBDOMAIN}.zendesk.com/api/v2/triggers/#{id}.json"
#   # puts targeturl
#   c.url = targeturl
#   c.http_put (data)
#   results = JSON.parse (c.body_str)
#   if !results["error"].nil?
#     puts "ERROR: cannot activate trigger ID #{id}"
#     puts "Error description: #{results["description"]}"
#     puts "Error details: #{results["details"]["base"][0]["description"]}"
#     error_count += 1
#   end
# end

# puts 'errors detected - please check log for details' if error_count > 0


