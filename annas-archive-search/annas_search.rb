#!/usr/bin/env ruby

begin
require 'json'
require 'fileutils'
require 'digest'
require 'colorize'
rescue LoadError => e
  puts "Missing required gem: #{e.message}"
  puts "Install with: gem install nokogiri"
  exit 1
end

require_relative 'lib/config'
require_relative 'lib/errors'
require_relative 'lib/cache'
require_relative 'lib/network'
require_relative 'lib/parser'
require_relative 'lib/book_builder'
require_relative 'lib/display'
require_relative 'lib/browser'
require_relative 'lib/input'

Config.validate

# Main execution
Cache.cleanup(Config.cache[:dir], Config.cache[:ttl], Config.cache[:cleanup_probability])
if ARGV.empty?
  puts "Usage: ruby annas_search.rb 'search string' [selection]"
  puts "  selection: optional number(s) to open (comma-separated or 'all')"
  puts "  Examples:"
  puts "    ruby annas_search.rb 'ruby programming'"
  puts "    ruby annas_search.rb 'ruby programming' 1"
  puts "    ruby annas_search.rb 'ruby programming' '1,3,5'"
  exit 1
end

search = ARGV[0]
selection = ARGV[1]

# Validate search query
unless Input.validate_search_query(search)
  puts "Error: Invalid search query"
  puts "Query must be 1-200 characters and not contain special characters like < > ; & | ` $ ( ) { } [ ]"
  exit 1
end

url = Network.build_search_url(search, Config.network[:base_url])
cache_file = Cache.get_file(search, Config.cache[:dir])

# Try cache first
begin
  books = Cache.load(cache_file, Config.cache[:ttl])
rescue => e
  if Errors.handle_cache(e, "load")
    # Clear corrupted cache
    File.delete(cache_file) if File.exist?(cache_file)
    books = nil
  else
    books = nil
  end
end

# Fetch if no cache or expired
unless books
  begin
    puts "Searching Anna's Archive..."
    doc = Network.fetch_html(url, Config.network[:open_timeout], Config.network[:read_timeout])
    raw_results = Parser.extract_raw_results(doc, Config.parsing[:result_selector])
    books = BookBuilder.build_books(raw_results, Config.parsing[:author_selector], Config.parsing[:date_regex], Config.parsing[:filetype_regex], Config.network[:base_url])
    begin
      Cache.save(cache_file, books)
    rescue => e
      Errors.handle_cache(e, "save")
    end
    puts "Found #{books.size} books"
   rescue => e
    Errors.handle_network(e)
  end
end

if books.empty?
  puts "No books found."
  exit 0
end

Display.display_books(books, Config.display[:title_max_len], Config.display[:author_max_len])

# Handle selection
input = Input.get(selection)
exit 0 if input.empty?

selections = Input.parse_selection_by_position(input, books)
browser_cmd = Config.browsers[:cmd] || Config.browsers[:fallbacks].first
selections.each { |i| Browser.open(books[i], Config.browsers[:fallbacks], Config.debug, Config.display[:title_max_len]) } if selections.any?