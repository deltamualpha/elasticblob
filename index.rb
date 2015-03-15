#!/usr/bin/env ruby

require 'optparse'
require 'base64'
require 'json'
require 'elasticsearch'

options = {}

optparse = OptionParser.new do|opts|
	opts.banner = "Usage: " + File.basename($0) + " [options] path1 path2 ..."

	options[:verbose] = false
	opts.on( '-v', '--verbose', 'Output more information' ) do
		options[:verbose] = true
	end

	options[:ignore_warnings] = false
	opts.on( '--ignore_warnings', 'Suppress warnings' ) do
		options[:ignore_warnings] = true
	end

	options[:index] = false
	opts.on( '-i INDEX', '--index INDEX', 'Index name to use.' ) do |index|
		options[:index] = index
	end

	options[:filetypes] = "doc,html,docx,pdf,txt"
	opts.on( '-f TYPES', '--filetypes TYPES', 'Comma-separated list of filetypes to index. Defaults to #{options[:filetypes]}' ) do |filetypes|
		options[:filetypes] = filetypes
	end

	options[:endpoint] = 'localhost:9200/'
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

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to index.

optparse.parse!

client = Elasticsearch::Client.new(
	hosts: options[:endpoint]
)

if !options[:index]
	exit
end

# if the index doesn't exist, set it up with the right type
if !client.indices.exists?(index: index)
	client.indices.create(
		index: index,
		type: 'document',
		body: { mappings: { document: { properties: { content: { type: "attachment" }}}}}
	)
end

filepaths = ARGV.product(options[:filetypes].split(",")).map { |x| x.join("/**/*.") }

filepaths.each do |path|
	files = Dir[path]
	# write each file into the index
	files.each do |file|
		puts File.basename(file)
		client.index({
			index: index.downcase,
			type: 'document',
			body: { 
				title: File.basename(file),
				filename: File.basename(file),
				content: Base64.strict_encode64(IO.binread(file))
			}
		})
	end
end
