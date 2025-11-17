#!/usr/bin/env ruby

begin
require 'nokogiri'
require 'open-uri'
require 'json'
require 'fileutils'
require 'digest'
rescue LoadError => e
  puts "Missing required gem: #{e.message}"
  puts "Install with: gem install nokogiri"
  exit 1
end

# Configuration
CACHE_DIR = File.expand_path('~/.cache/annas_search')
CACHE_TTL = 3600  # 1 hour
TITLE_MAX_LEN = 50
AUTHOR_MAX_LEN = 30
BROWSER_CMD = ENV['BROWSER_COMMAND'] || 'brave --app'

# Validate configuration
begin
  FileUtils.mkdir_p(CACHE_DIR)
rescue => e
  puts "Failed to create cache directory: #{e.message}"
  exit 1
end

def truncate(str, len)
  str.length > len ? "#{str[0...len]}..." : str
end

def truncate_title(str) = truncate(str, TITLE_MAX_LEN)
def truncate_author(str) = truncate(str, AUTHOR_MAX_LEN)

def parse_books(doc)
  doc.css('.flex.pt-3.pb-3').each_with_index.filter_map do |result, index|
    text = result.text.strip
    next if text.include?("Your ad here.")

    # Extract all data in single pass
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    title = lines[1] || lines[0]

    author_link = result.at_css('a[href*="/search?q="]')
    author = author_link&.text&.strip
    next unless author

    # Single regex pass for date and filetype
    date_match = text.match(/\b(19[0-9]{2}|20[0-2][0-9])\b/)
    filetype_match = text.match(/ · ([A-Z]{3,4}) · /)

    book_link = result.at_css('a')
    url = book_link ? "https://annas-archive.org#{book_link['href']}" : nil

    {
      title: title,
      author: author,
      date: date_match ? date_match[0] : nil,
      url: url,
      index: index + 1,
      filetype: filetype_match ? filetype_match[1] : nil
    }
  end
end

def display_books(books)
  puts "Found books:"
  books.each do |book|
    date = book[:date] || "Unknown Date"
    prefix = book[:filetype] ? "[#{book[:filetype]}] " : ""
    puts "#{prefix}#{book[:index]}. \"#{truncate_title(book[:title])}\" by #{truncate_author(book[:author])} (#{date})"
  end
end

def parse_selection(input, count)
  return (0...count).to_a if input.downcase == 'all'
  input.split(',').map { |n| n.strip.to_i - 1 }.select { |n| n.between?(0, count - 1) }
end

def open_browser(book)
  return unless book[:url]
  cmd = "#{BROWSER_CMD} '#{book[:url]}'"
  success = system(cmd)
  puts "Opened: #{truncate_title(book[:title])}" if success
end

def get_cache_file(search)
  "#{CACHE_DIR}/#{Digest::SHA256.hexdigest(search)}.json"
end

def load_cache(cache_file)
  return nil unless File.exist?(cache_file)
  return nil if (Time.now - File.mtime(cache_file)) >= CACHE_TTL

  begin
    JSON.parse(File.read(cache_file), symbolize_names: true)
  rescue JSON::ParserError
    nil
  end
end

def save_cache(cache_file, books)
  File.write(cache_file, JSON.generate(books)) unless books.empty?
end

# Main execution
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
url = "https://annas-archive.org/search?q=#{URI.encode_www_form_component(search)}"
cache_file = get_cache_file(search)

# Try cache first
books = load_cache(cache_file)

# Fetch if no cache or expired
unless books
  begin
    puts "Searching Anna's Archive..."
    doc = Nokogiri::HTML(URI.open(url, open_timeout: 10, read_timeout: 30))
    books = parse_books(doc)
    save_cache(cache_file, books)
    puts "Found #{books.size} books"
  rescue OpenURI::HTTPError => e
    puts "HTTP error: #{e.message}"
    exit 1
  rescue SocketError => e
    puts "Network error: Check your internet connection"
    exit 1
  rescue => e
    puts "Failed to fetch results: #{e.message}"
    exit 1
  end
end

if books.empty?
  puts "No books found."
  exit 0
end

display_books(books)

# Handle selection
input = selection || (puts("Enter numbers (comma-separated or 'all'):"); STDIN.gets&.chomp&.strip || '')
exit 0 if input.empty?

selections = parse_selection(input, books.size)
selections.each { |i| open_browser(books[i]) } if selections.any?