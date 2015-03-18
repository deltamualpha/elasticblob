#!/usr/bin/env ruby

require 'optparse'
require 'elasticsearch'

options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: " + File.basename($0) + " [options] term1 term2..."

  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:index] = false
  opts.on( '-i INDEX', '--index INDEX', 'Index name to use' ) do |index|
    options[:index] = index
  end

  options[:phrase] = false
  opts.on( '-p', '--phrase', 'Search as a single phrase instead of single words' ) do
    options[:phrase] = true
  end

  options[:elements] = false
  opts.on( '-t TAGS', '--tags TAGS', 'A comma-separated list of fields to limit the search to. By default, searches all fields.' ) do |tags|
    options[:elements] = tags.split(",")
  end

  options[:limit] = 10
  opts.on( '-l 10', '--limit 10', 'Maximum number of results to return. Defaults to 10.' ) do |limit|
    options[:limit] = limit
  end

  options[:endpoint] = 'localhost:9200'
  opts.on( '-e URL', '--endpoint URL', 'URL for the elasticsearch instance. Defaults to localhost on 9200.' ) do |url|
    options[:endpoint] = url
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

client = Elasticsearch::Client.new({hosts: options[:endpoint]})

if !options[:index]
  exit
end

index = options[:index].downcase

if options[:phrase]
  query = { match_phrase: { _all: ARGV.join(" ") } }
end

if options[:elements]
  query = { multi_match: { query: ARGV.join(" "), fields: options[:elements] } }
  if options[:phrase]
    query[:multi_match][:type] = "phrase"
  end
end

if !query
  query = { match: { _all: ARGV.join(" ") } }
end

query_body = {
  query: query,
  partial_fields: {
    main_fields: {
      include: ["_id", "title"]
    },
    custom_fields: {
      exclude: ["_content", "content", "_id", "title", "fullpath"]
    },
    fullpath: {
      include: ["fullpath"]
    }
  },
  sort: ["_score"]
}

if options[:limit]
  query_body[:size] = options[:limit]
end

results = client.search( index: index, body: query_body )

puts "---"

results["hits"]["hits"].each do |hit|
  puts "Title: #{hit["fields"]["main_fields"][0]["title"]}"

  hit["fields"]["custom_fields"][0].each do |name, field|
    puts "#{name.capitalize}: #{field}"
  end
  
  puts "Path: file://#{URI.escape(hit["fields"]["fullpath"][0]["fullpath"])}"
  
  puts "---"
end
