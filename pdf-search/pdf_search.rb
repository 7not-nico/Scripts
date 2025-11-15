#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'open-uri'
require 'fileutils'

if ARGV.empty?
  puts "Usage: ruby pdf_search.rb 'search string'"
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

FileUtils.mkdir_p('output')

results.each do |result|
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