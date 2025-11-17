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
require_relative 'lib/display'
require_relative 'lib/browser'
require_relative 'lib/input'

Config.validate

# Main execution
Cache.cleanup(Config::CACHE[:dir], Config::CACHE[:ttl], Config::CACHE[:cleanup_probability])
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
url = Network.build_search_url(search, Config::NETWORK[:base_url])
cache_file = Cache.get_file(search, Config::CACHE[:dir])

# Try cache first
books = Cache.load(cache_file, Config::CACHE[:ttl])

# Fetch if no cache or expired
unless books
  begin
    puts "Searching Anna's Archive..."
    doc = Network.fetch_html(url, Config::NETWORK[:open_timeout], Config::NETWORK[:read_timeout])
    books = Parser.parse_books(doc, Config::PARSING[:result_selector], Config::PARSING[:author_selector], Config::PARSING[:date_regex], Config::PARSING[:filetype_regex], Config::NETWORK[:base_url])
    Cache.save(cache_file, books)
    puts "Found #{books.size} books"
   rescue => e
    Errors.handle_network(e)
  end
end

if books.empty?
  puts "No books found."
  exit 0
end

Display.display_books(books, Config::DISPLAY[:title_max_len], Config::DISPLAY[:author_max_len])

# Handle selection
input = Input.get(selection)
exit 0 if input.empty?

selections = Input.parse_selection(input, books.size)
browser_cmd = Config::BROWSERS[:cmd] || Config::BROWSERS[:fallbacks].first
selections.each { |i| Browser.open(books[i], Config::BROWSERS[:fallbacks], Config::DEBUG, Config::DISPLAY[:title_max_len]) } if selections.any?