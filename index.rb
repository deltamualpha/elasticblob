#!/usr/bin/env ruby

require 'optparse'
require 'base64'
require 'elasticsearch'
require 'yaml'

options = {}

optparse = OptionParser.new do|opts|
	opts.banner = "Usage: " + File.basename($0) + " [options] path1 path2 ..."

	options[:verbose] = false
	opts.on( '-v', '--verbose', 'Output more information' ) do
		options[:verbose] = true
	end

	options[:index] = false
	opts.on( '-i INDEX', '--index INDEX', 'Index name to use.' ) do |index|
		options[:index] = index
	end

	options[:filetypes] = "doc,docx,pdf,html,txt"
	opts.on( '-f TYPES', '--filetypes TYPES', 'Comma-separated list of filetypes to index. Defaults to #{options[:filetypes]}' ) do |filetypes|
		options[:filetypes] = filetypes
	end

	options[:metadata] = false
	opts.on( '-m FILE', '--metadata FILE', 'Location for a metadata file; see readme for details' ) do |file|
		options[:metadata] = file
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

if options[:metadata]
	metadata = YAML.load(File.open(options[:metadata]))
end

index = options[:index].downcase

# if the index doesn't exist, set it up with the right type
if !client.indices.exists?(index: index)
	client.indices.create(
		index: index,
		type: 'document',
		body: { mappings: { document: { properties: { _content: { type: "attachment" }}}}}
	)
end

filepaths = ARGV.product(options[:filetypes].split(",")).map { |x| x.join("/**/*.") }

filepaths.each do |path|
	files = Dir[path]
	puts "Reading " + path
	# write each file into the index
	files.each do |file|
		if options[:verbose]
			puts File.basename(file)
		end

		body = {
			title: File.basename(file),
			_id: File.realpath(file),
			filename: File.basename(file),
			fullpath: File.realpath(file),
			_content: Base64.strict_encode64(IO.binread(file))
		}

		if metadata[File.basename(file)]
			body.merge!(metadata[File.basename(file)])
		end

		client.index({
			index: index,
			type: 'document',
			id: File.realpath(file),
			body: body
		})
	end
end
