#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'fileutils'

if ARGV.empty?
  puts "Usage: ruby annas_direct_search.rb 'search string'"
  exit 1
end

search_string = ARGV[0]
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
  title_element = result.at_css('h3 a')
  next unless title_element
  title = title_element.text.strip
  link = title_element['href']
  puts "#{i + 1}. #{title}"
  puts "   Link: https://annas-archive.org#{link}"
  puts ""
end

puts "Enter numbers to download (comma-separated, e.g., 1,3,5 or 'all'):"
input = STDIN.gets.chomp.strip

selected_indices = if input.downcase == 'all'
                     (0...results.size).to_a
                   else
                     input.split(',').map(&:strip).map(&:to_i).map { |n| n - 1 }.select { |n| n >= 0 && n < results.size }
                   end

if selected_indices.empty?
  puts "No valid selections. Exiting."
  exit 0
end

FileUtils.mkdir_p('output')

selected_indices.each do |i|
  result = results[i]
  title_element = result.at_css('h3 a')
  next unless title_element
  title = title_element.text.strip
  link = title_element['href']
  book_url = "https://annas-archive.org#{link}"

  begin
    puts "Opening Brave for: #{title} at #{book_url}"
    system("brave '#{book_url}' 2>/dev/null")
    puts "Opened Brave for: #{title}"
  rescue => e
    puts "Failed to open Brave for #{title}: #{e.message}"
  end
    filename = title.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '') + ".#{format}"
    filepath = File.join('output', filename)
    
    puts "Downloading #{filename}..."
    URI.open(download_url) do |f|
      File.write(filepath, f.read)
    end
    puts "Downloaded: #{filename}"
  rescue => e
    puts "Failed to download #{title}: #{e.message}"
  end
end