#!/usr/bin/env ruby

require 'fileutils'

# Usage: ruby content_sorter.rb [directory]
# Sorts files in the specified directory (default: output/) by name

dir = ARGV[0] || 'pdf-search/output'

unless Dir.exist?(dir)
  puts "Directory '#{dir}' does not exist."
  exit 1
end

files = Dir.glob("#{dir}/*.pdf").sort_by { |f| File.basename(f).downcase }

puts "Sorted PDF files in '#{dir}':"
files.each_with_index do |file, index|
  puts "#{index + 1}. #{File.basename(file)}"
end

# Optional: Move files to sorted names if needed
# For example, rename to 01_file.pdf, etc.
# Uncomment below to enable
# files.each_with_index do |file, index|
#   ext = File.extname(file)
#   new_name = format('%02d%s', index + 1, ext)
#   new_path = File.join(dir, new_name)
#   FileUtils.mv(file, new_path)
#   puts "Renamed: #{File.basename(file)} -> #{new_name}"
# end