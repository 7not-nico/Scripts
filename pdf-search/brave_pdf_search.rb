#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'fileutils'

# Usage: ruby brave_pdf_search.rb 'search query'
if ARGV.empty?
  puts "Usage: ruby brave_pdf_search.rb 'search query'"
  exit 1
end

search_query = ARGV[0]
query = "#{search_query} filetype:pdf"
encoded_query = URI.encode_www_form_component(query)
url = "https://search.brave.com/search?q=#{encoded_query}"

begin
  html = URI.open(url, 'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36').read
  doc = Nokogiri::HTML(html)

  # Extract PDF links from result anchors
  urls = doc.css('a.heading-serpresult').map { |link| link['href'] }.select { |href| href && href.include?('.pdf') }.take(10)
  puts "Found PDF URLs: #{urls}"

  FileUtils.mkdir_p('output')

  urls.each do |pdf_url|
    filename = pdf_url.split('/').last || 'download.pdf'
    filepath = File.join('output', filename)
    URI.open(pdf_url) do |remote|
      File.open(filepath, 'wb') do |local|
        local.write(remote.read)
      end
    end
    puts "Downloaded: #{filename}"
  rescue => e
    puts "Failed: #{pdf_url} - #{e.message}"
  end
rescue => e
  puts "Error fetching or parsing page: #{e.message}"
end

search_query = ARGV[0]
query = "#{search_query} filetype:pdf"

# Path to Brave binary (adjust if needed)
brave_path = '/usr/bin/brave'  # Linux default; change for your OS

options = Selenium::WebDriver::Chrome::Options.new
options.binary = brave_path
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')
options.add_argument('--disable-gpu')
options.add_argument('--window-size=1920,1080')

driver = Selenium::WebDriver.for :chrome, options: options

begin
  encoded_query = URI.encode_www_form_component(query)
  driver.get("https://search.brave.com/search?q=#{encoded_query}")

  # Wait for results to load
  wait = Selenium::WebDriver::Wait.new(timeout: 15)
  wait.until { driver.find_elements(css: 'a.heading-serpresult').size > 0 }

  results = driver.find_elements(css: 'a.heading-serpresult')  # Selector for Brave search result links
  urls = results.take(10).map { |link| link.attribute('href') }.select { |url| url && url.include?('.pdf') }
  puts "Found PDF URLs: #{urls}"

  FileUtils.mkdir_p('output')

  urls.each do |url|
    filename = url.split('/').last || 'download.pdf'
    filepath = File.join('output', filename)
    `curl -s -o "#{filepath}" "#{url}"`
    puts "Downloaded: #{filename}"
  rescue => e
    puts "Failed: #{url} - #{e.message}"
  end
ensure
  driver.quit
end