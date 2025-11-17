#!/usr/bin/env ruby

# Test runner for Anna's Archive Search
# Usage: ruby run_tests.rb

require 'fileutils'

test_dir = File.dirname(__FILE__)
test_files = Dir.glob(File.join(test_dir, 'test_*.rb'))

puts "Running Anna's Archive Search Tests"
puts "=" * 40

all_passed = true

test_files.each do |test_file|
  puts "\nRunning #{File.basename(test_file)}..."
  puts "-" * 30
  
  result = system("ruby #{test_file}")
  
  if result
    puts "✓ PASSED"
  else
    puts "✗ FAILED"
    all_passed = false
  end
end

puts "\n" + "=" * 40
if all_passed
  puts "All tests passed! ✓"
  exit 0
else
  puts "Some tests failed! ✗"
  exit 1
end