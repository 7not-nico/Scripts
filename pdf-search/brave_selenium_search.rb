#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'fileutils'

if ARGV.empty?
  puts "Usage: ruby brave_selenium_search.rb 'search string'"
  exit 1
end

search_string = ARGV[0]
query = "#{search_string} ext:pdf"

# Assumes Firefox with geckodriver installed
driver = Selenium::WebDriver.for :firefox
driver.get 'https://search.brave.com/'

begin
  search_box = driver.find_element(name: 'q')
  search_box.send_keys query
  search_box.submit

  sleep 3  # Wait for results

  results = driver.find_elements(css: '.snippet')

  pdfs = []
  results.each do |result|
    title_element = result.find_element(css: 'h4 a')
    url_element = result.find_element(css: 'cite')
    title = title_element.text
    url = url_element.text
    if url.end_with?('.pdf')
      pdfs << { title: title, url: url }
    end
  end

  if pdfs.empty?
    puts "No PDFs found."
    driver.quit
    exit 0
  end

  puts "Found PDFs:"
  pdfs.each_with_index do |pdf, i|
    puts "#{i + 1}. #{pdf[:title]} - #{pdf[:url]}"
  end

  puts "Enter numbers to download (comma-separated, e.g., 1,3,5 or 'all'):"
  input = gets.chomp.strip

  selected_indices = if input.downcase == 'all'
                       (0...pdfs.size).to_a
                     else
                       input.split(',').map(&:strip).map(&:to_i).map { |n| n - 1 }.select { |n| n >= 0 && n < pdfs.size }
                     end

  if selected_indices.empty?
    puts "No valid selections."
    driver.quit
    exit 0
  end

  FileUtils.mkdir_p('output')

  selected_indices.each do |i|
    pdf = pdfs[i]
    url = pdf[:url]
    title = pdf[:title]
    filename = title.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '') + '.pdf'
    filepath = File.join('output', filename)
    begin
      require 'open-uri'
      URI.open(url) do |f|
        File.write(filepath, f.read)
      end
      puts "Downloaded: #{filename}"
    rescue => e
      puts "Failed to download #{url}: #{e.message}"
    end
  end

ensure
  driver.quit
end