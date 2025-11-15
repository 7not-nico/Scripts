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
             raw_author = author_element.text.strip
             # Deduplicate repeated names
             parts = raw_author.split(/[,;&]/).map(&:strip).uniq
             parts.join(', ')
           else
             "Unknown Author"
           end

  # Extract date from text with validation
  full_date_match = result_text.match(/(\w+ \d{1,2}, \d{4})/)
  if full_date_match
    date = full_date_match[1]
  else
    year_match = result_text.match(/\b(19[0-9]{2}|20[0-2][0-9])\b/)
    date = year_match ? year_match[1] : "Unknown Date"
  end

  # Skip ads
  next if title == "Your ad here." || author == "Unknown Author"

  # Format display with truncation
  truncated_title = title.length > 50 ? title[0..47] + "..." : title
  truncated_author = author.length > 30 ? author[0..27] + "..." : author
  puts "#{i + 1}. \"#{truncated_title}\" by #{truncated_author} (#{date})"
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
  if system("brave --app='#{book_url}' 2>/dev/null")
    puts "Opened successfully."
  else
    puts "Failed to open Brave. Try: brave-browser --app='#{book_url}'"
  end
end