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
CACHE_CLEANUP_PROBABILITY = 0.1  # 10% chance to cleanup on each run
TITLE_MAX_LEN = 50
AUTHOR_MAX_LEN = 30
OPEN_TIMEOUT = 10
READ_TIMEOUT = 30
BROWSER_FALLBACKS = ['brave --app', 'firefox --new-window', 'chromium --app']
BROWSER_CMD = ENV['BROWSER_COMMAND'] || BROWSER_FALLBACKS.first
BASE_URL = 'https://annas-archive.org'
RESULT_SELECTOR = '.flex.pt-3.pb-3'
AUTHOR_SELECTOR = 'a[href*="/search?q="]'
DATE_REGEX = Regexp.new(/\b(19[0-9]{2}|20[0-2][0-9])\b/)
FILETYPE_REGEX = Regexp.new(/ · ([A-Z]{3,4}) · /)

# Validate configuration
begin
  FileUtils.mkdir_p(CACHE_DIR)
rescue => e
  handle_error("Failed to create cache directory: #{e.message}")
end

def truncate(str, len)
  str.length > len ? "#{str[0...len]}..." : str
end

def truncate_title(str) = truncate(str, TITLE_MAX_LEN)
def truncate_author(str) = truncate(str, AUTHOR_MAX_LEN)

def extract_book_data(result, index)
  text = result.text.strip
  return nil if text.include?("Your ad here.")

  lines = text.split("\n").map(&:strip).reject(&:empty?)
  title = lines[1] || lines[0]

  author_link = result.at_css(AUTHOR_SELECTOR)
  author = author_link&.text&.strip
  return nil unless author

  date_match = text.match(DATE_REGEX)
  filetype_match = text.match(FILETYPE_REGEX)

  book_link = result.at_css('a')
  url = book_link ? "#{BASE_URL}#{book_link['href']}" : nil

  {
    title: title,
    author: author,
    date: date_match ? date_match[0] : nil,
    url: url,
    index: index + 1,
    filetype: filetype_match ? filetype_match[1] : nil
  }
end

def parse_books(doc)
  doc.css(RESULT_SELECTOR).each_with_index.filter_map do |result, index|
    extract_book_data(result, index)
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
  BROWSER_FALLBACKS.each do |browser|
    next unless browser_available?(browser)
    cmd = "#{browser} '#{book[:url]}'"
    success = system(cmd)
    if success
      puts "Opened: #{truncate_title(book[:title])}"
      return
    end
  end
  puts "Failed to open browser for: #{truncate_title(book[:title])}"
end

def get_cache_file(search)
  "#{CACHE_DIR}/#{Digest::SHA256.hexdigest(search)}.json"
end

def load_cache(cache_file)
  return nil unless File.exist?(cache_file) && (Time.now - File.mtime(cache_file)) < CACHE_TTL

  begin
    JSON.parse(File.read(cache_file), symbolize_names: true)
  rescue JSON::ParserError
    nil
  end
end

def save_cache(cache_file, books)
  File.write(cache_file, JSON.generate(books)) unless books.empty?
end

def cleanup_cache(probability = CACHE_CLEANUP_PROBABILITY)
  return unless rand < probability
  Dir.glob("#{CACHE_DIR}/*.json").each do |file|
    File.delete(file) if (Time.now - File.mtime(file)) >= CACHE_TTL
  end
end

def get_user_input(selection)
  return selection if selection
  puts "Enter numbers (comma-separated or 'all'):"
  STDIN.gets&.chomp&.strip || ''
end

def handle_error(message, exit_code = 1)
  puts "Error: #{message}"
  exit exit_code
end

def browser_available?(browser_cmd)
  system("#{browser_cmd} --version >/dev/null 2>&1")
end

# Main execution
cleanup_cache
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
url = "#{BASE_URL}/search?q=#{URI.encode_www_form_component(search)}"
cache_file = get_cache_file(search)

# Try cache first
books = load_cache(cache_file)

# Fetch if no cache or expired
unless books
  begin
    puts "Searching Anna's Archive..."
    doc = Nokogiri::HTML(URI.open(url, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT))
    books = parse_books(doc)
    save_cache(cache_file, books)
    puts "Found #{books.size} books"
   rescue OpenURI::HTTPError => e
     handle_error("HTTP #{e.message}")
   rescue SocketError => e
     handle_error("Network connection failed")
   rescue => e
     handle_error("Failed to fetch results - #{e.message}")
  end
end

if books.empty?
  puts "No books found."
  exit 0
end

display_books(books)

# Handle selection
input = get_user_input(selection)
exit 0 if input.empty?

selections = parse_selection(input, books.size)
selections.each { |i| open_browser(books[i]) } if selections.any?