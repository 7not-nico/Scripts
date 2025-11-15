#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'open-uri'
require 'fileutils'

if ARGV.empty?
  puts "Usage: ruby pdf_selector.rb 'search string'"
  exit 1
end

search_string = ARGV[0]
query = "#{search_string} ext:pdf"

api_key = ENV['BRAVE_API_KEY']
if api_key.nil?
  puts "Please set BRAVE_API_KEY environment variable"
  exit 1
end

uri = URI('https://api.search.brave.com/res/v1/web/search')
params = { q: query }
uri.query = URI.encode_www_form(params)

req = Net::HTTP::Get.new(uri)
req['X-Subscription-Token'] = api_key

res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(req)
end

unless res.is_a?(Net::HTTPSuccess)
  puts "Search failed: #{res.code} #{res.message}"
  exit 1
end

data = JSON.parse(res.body)
results = data.dig('web', 'results') || []

if results.empty?
  puts "No PDFs found."
  exit 0
end

puts "Found PDFs:"
results.each_with_index do |result, i|
  title = result['title'] || 'Untitled'
  url = result['url']
  puts "#{i + 1}. #{title} - #{url}"
end

puts "Enter numbers to download (comma-separated, e.g., 1,3,5 or 'all'):"
input = gets.chomp.strip

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
  url = result['url']
  title = result['title'] || 'untitled'
  filename = title.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '') + '.pdf'
  filepath = File.join('output', filename)
  begin
    URI.open(url) do |f|
      File.write(filepath, f.read)
    end
    puts "Downloaded: #{filename}"
  rescue => e
    puts "Failed to download #{url}: #{e.message}"
  end
end