#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'json'

# Constants
CACHE_TTL = 3600  # 1 hour
TITLE_MAX_LEN = 50
AUTHOR_MAX_LEN = 30

def truncate(str, len)
  str.length > len ? "#{str[0...len]}..." : str
end

# Utility functions
def truncate_title(str) = truncate(str, TITLE_MAX_LEN)
def truncate_author(str) = truncate(str, AUTHOR_MAX_LEN)

def parse_book(result, index)
  text = result.text.strip
  return nil if text.include?("Your ad here.")

  # Extract all data in single pass
  lines = text.split("\n").map(&:strip).reject(&:empty?)
  title = lines[1] || lines[0]

  author_link = result.at_css('a[href*="/search?q="]')
  author = author_link&.text&.strip
  return nil unless author

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
  system("brave --app '#{book[:url]}'") if book[:url]
end

# Main execution
if ARGV.empty?
  puts "Usage: ruby annas_search.rb 'search string' [selection]"
  exit 1
end

search = ARGV[0]
selection = ARGV[1]
url = "https://annas-archive.org/search?q=#{URI.encode_www_form_component(search)}"
cache_file = ".annas_cache_#{search.hash}"

books = if File.exist?(cache_file) && (Time.now - File.mtime(cache_file)) < CACHE_TTL
  begin
    JSON.parse(File.read(cache_file), symbolize_names: true)
  rescue JSON::ParserError
    nil
  end
end

unless books
  begin
    doc = Nokogiri::HTML(URI.open(url, open_timeout: 10, read_timeout: 30))
    books = doc.css('.flex.pt-3.pb-3').each_with_index.filter_map { |r, i| parse_book(r, i) }
    File.write(cache_file, JSON.generate(books)) if books.size > 0
  rescue => e
    puts "Failed to fetch: #{e.message}"
    exit 1
  end
end

if books.empty?
  puts "No books found."
  exit 0
end

display_books(books)

input = selection || (puts("Enter numbers (comma-separated or 'all'):"); STDIN.gets&.chomp&.strip || '')
exit 0 if input.empty?

selections = parse_selection(input, books.size)
selections.each { |i| open_browser(books[i]) } if selections.any?