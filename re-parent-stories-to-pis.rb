# Copyright 2002-2013 Rally Software Development Corp. All Rights Reserved.
#
# This script is open source and is provided on an as-is basis. Rally provides
# no official support for nor guarantee of the functionality, usability, or
# effectiveness of this code, nor its suitability for any application that
# an end-user might have in mind. Use at your own risk: user assumes any and
# all risk associated with use and implementation of this script in his or
# her own environment.

require 'rally_api'
require 'csv'

$my_base_url       = "https://rally1.rallydev.com/slm"

$my_username       = "user@company.com"
$my_password       = "password"
$my_workspace      = "My Workspace"
$my_project        = "My Project"
$wsapi_version     = "1.40"

$filename          = 'parent_portfolio_items.csv'

# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

def assign_parent_portfolio_item(header, row)

  user_story_formatted_id      = row[header[0]].strip
  user_story_name              = row[header[1]].strip
  parent_pi_formatted_id       = row[header[2]].strip
  parent_pi_type               = row[header[3]].gsub(/\s+/, "").downcase
  parent_pi_name               = row[header[4]].strip

  story_fetch_string = "ObjectID,FormattedID,Name,Owner,ScheduleState,Description"
  pi_fetch_string = "ObjectID,FormattedID,Name,PortfolioItemType,Name"
  order_string = "FormattedID Asc"

  user_story_query_string = "(FormattedID = \"" + user_story_formatted_id + "\")"

  parent_formatted_id_query_string = "(FormattedID = \"" + parent_pi_formatted_id + "\")"
  parent_name_query_string = "(Name = \"" + parent_pi_name + "\")"

  # Grab the story
  story_query = RallyAPI::RallyQuery.new()
  story_query.type = "hierarchicalrequirement"
  story_query.fetch = story_fetch_string
  story_query.query_string = user_story_query_string
  story_query.order = order_string

  story_results = @rally.find(story_query)

  # First Construct and Try queries based on Formatted ID
  parent_query_by_formatted_id = RallyAPI::RallyQuery.new()
  parent_type_string = "portfolioitem/" + parent_pi_type
  parent_query_by_formatted_id.type = parent_type_string
  parent_query_by_formatted_id.fetch = pi_fetch_string
  parent_query_by_formatted_id.query_string = parent_formatted_id_query_string
  parent_query_by_formatted_id.order = order_string

  parent_results_by_formatted_id = @rally.find(parent_query_by_formatted_id)

  # Annoying bug in custom PI FormattedID's causes even correct FormattedID queries with confirmed
  # FormattedID present, to fail... so, try name-based lookup instead if this fails
  if parent_results_by_formatted_id.total_result_count == 0
    puts "Parent PI Item #{parent_pi_formatted_id}: #{parent_pi_name} not found via FormattedID Query...trying query by Name"

    parent_query_by_name = RallyAPI::RallyQuery.new()
    parent_query_by_name.type = parent_type_string
    parent_query_by_name.fetch = fetch_string
    parent_query_by_name.query_string = parent_name_query_string
    parent_query_by_name.order = order_string

    parent_results_by_name = @rally.find(parent_query_by_name)
  else
    my_parent_results = parent_results_by_formatted_id
    parent_results_by_name = {}
    parent_results_by_name = parent_results_by_formatted_id
  end

  # Handle the situation if either name-based lookup produces no results,
  # or, if the name-based lookup produces multiple, non-unique results

  if story_results.total_result_count == 0 || parent_results_by_name.total_result_count == 0 || \
        story_results.total_result_count > 1 || parent_results_by_name.total_result_count > 1
    if story_results.total_result_count == 0
      puts "User Story #{user_story_formatted_id}: #{user_story_name} not found ...Skipping"
    end
    if parent_results_by_name.total_result_count == 0
      puts "Parent PI Item #{parent_pi_formatted_id}: #{parent_pi_name} not found via Name query...Skipping"
    end
    if parent_results_by_name.total_result_count > 1
      puts "Multiple Parent PI Items Found with Name: #{parent_pi_name} with name-based query."
      parent_results_by_name.each do | this_parent |
        puts "FormattedID: #{this_parent.FormattedID}"
      end
    end

  # Finally, attempt to update the User Story with the new Parent PI
  else
    begin

      if my_parent_results.nil? then my_parent_results = parent_results_by_name end

      story_to_update = story_results.first
      fields = {}
      fields["PortfolioItem"] = my_parent_results.first
      story_updated = @rally.update("hierarchicalrequirement", story_to_update.ObjectID, fields) #by ObjectID
      puts "User Story #{user_story_formatted_id}: #{user_story_name} successfully updated parent to: "
      puts "   ==> Parent #{parent_pi_formatted_id}: #{parent_pi_name}"
    rescue => ex
      puts  "User Story #{user_story_formatted_id}: #{user_story_name} not updated due to error"
      puts ex.message
      puts ex.backtrace.join("\n")
      puts ex
    end
  end
end

begin

  #==================== Making a connection to Rally ====================
  config                  = {:base_url => $my_base_url}
  config[:username]       = $my_username
  config[:password]       = $my_password
  config[:headers]        = $my_headers #from RallyAPI::CustomHttpHeader.new()
  config[:workspace]      = $my_workspace
  config[:project]        = $my_project
  config[:version]        = $wsapi_version

  @rally = RallyAPI::RallyRestJson.new(config)

  input  = CSV.read($filename)

  header = input.first #ignores first line

  rows   = []

  (1...input.size).each { |i| rows << CSV::Row.new(header, input[i]) }

  rows.each do |row|
    assign_parent_portfolio_item(header, row)
  end
end