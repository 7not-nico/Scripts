#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'fileutils'

if ARGV.empty?
  puts "Usage: ruby annas_search.rb 'search string' [selection]"
  puts "If selection is provided, automatically selects that number."
  exit 1
end

search_string = ARGV[0]
auto_selection = ARGV[1]
url = "https://annas-archive.org/search?q=#{URI.encode_www_form_component(search_string)}"

begin
  doc = Nokogiri::HTML(URI.open(url))
rescue => e
  puts "Failed to fetch search page: #{e.message}"
  exit 1
end

results = doc.css('.flex.pt-3.pb-3')

if results.empty?
  puts "No books found."
  exit 0
end

puts "Found books:"
results.each_with_index do |result, i|
  link_element = result.at_css('a')
  next unless link_element
  link = link_element['href']
  result_text = result.text.strip

  # Extract title from result text lines
  lines = result_text.split("\n").map(&:strip).reject(&:empty?)
  title = lines[1] || lines[0] || "Unknown Title"

  # Extract author from search link
  author_element = result.css('a[href*="/search?q="]').first
  author = if author_element
             author_element.text.strip
           else
             "Unknown Author"
           end

  # Extract date from text
  date_match = result_text.match(/(\w+ \d+, \d{4}|\d{4})/)
  date = date_match ? date_match[1] : "Unknown Date"

  # Format display
  puts "#{i + 1}. \"#{title}\" by #{author} (#{date})"
end

if auto_selection
  input = auto_selection
else
  puts "Enter numbers to download (comma-separated, e.g., 1,3,5 or 'all'):"
  input = STDIN.gets
  if input.nil?
    puts "No input provided. Exiting."
    exit 0
  end
  input = input.chomp.strip
end

selected_indices = if input.downcase == 'all'
                     (0...results.size).to_a
                   else
                     input.split(',').map(&:strip).map(&:to_i).map { |n| n - 1 }.select { |n| n >= 0 && n < results.size }
                   end

if selected_indices.empty?
  puts "No valid selections. Exiting."
  exit 0
end

selected_indices.each do |i|
  result = results[i]
  link_element = result.at_css('a')
  next unless link_element
  link = link_element['href']
  result_text = result.text.strip
  lines = result_text.split("\n").map(&:strip).reject(&:empty?)
  title = lines[1] || lines[0] || "Unknown Title"
  book_url = "https://annas-archive.org#{link}"

  puts "Opening Brave for: #{title}"
  if system("brave-browser --app='#{book_url}' 2>/dev/null")
    puts "Opened successfully."
  else
    puts "Failed to open Brave. Try: brave-browser --app='#{book_url}'"
  end
end