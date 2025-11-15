#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

def extract_title(result)
  result_text = result.text.strip
  lines = result_text.split("\n").map(&:strip).reject(&:empty?)
  lines[1] || lines[0]
end

def extract_author(result)
  author_element = result.css('a[href*="/search?q="]').first
  author_element&.text&.strip
end

def extract_date(result)
  result_text = result.text.strip
  date_match = result_text.match(/(\w+ \d{1,2}, \d{4}|\b(19[0-9]{2}|20[0-2][0-9])\b)/)
  date_match ? date_match[1] || date_match[2] : nil
end

def extract_url(result)
  link_element = result.at_css('a')
  link_element ? "https://annas-archive.org#{link_element['href']}" : nil
end

def parse_results(doc)
  results = doc.css('.flex.pt-3.pb-3')
  results.each_with_index.map do |result, i|
    title = extract_title(result)
    author = extract_author(result)
    date = extract_date(result)
    url = extract_url(result)

    # Skip ads
    next if title == "Your ad here." || author.nil?

    { title: title, author: author, date: date, url: url, index: i + 1 }
  end.compact
end

def display_books(books)
  puts "Found books:"
  books.each do |book|
    truncated_title = book[:title] && book[:title].length > 50 ? book[:title][0..47] + "..." : book[:title]
    truncated_author = book[:author] && book[:author].length > 30 ? book[:author][0..27] + "..." : book[:author]
    date = book[:date] || "Unknown Date"
    puts "#{book[:index]}. \"#{truncated_title}\" by #{truncated_author} (#{date})"
  end
end

def parse_selection(input, book_count)
  return (0...book_count).to_a if input.downcase == 'all'

  input.split(',').map(&:strip).map(&:to_i).map { |n| n - 1 }.select { |n| n >= 0 && n < book_count }
end

def open_browser(book)
  puts "Opening Brave for: #{book[:title]}"
  url = book[:url]
  if system("brave --app='#{url}' 2>/dev/null")
    puts "Opened successfully."
  else
    puts "Failed to open Brave. Try: brave-browser --app='#{url}'"
  end
end

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

books = parse_results(doc)

if books.empty?
  puts "No books found."
  exit 0
end

display_books(books)

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

selected_indices = parse_selection(input, books.size)

if selected_indices.empty?
  puts "No valid selections. Exiting."
  exit 0
end

selected_indices.each do |i|
  book = books[i]
  open_browser(book)
end