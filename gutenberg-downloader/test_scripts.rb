#!/usr/bin/env ruby

require 'benchmark'

scripts = [
  "python download_books.py",
  "node download_books.js",
  "ruby download_books.rb",
  "cargo run --bin download_books",
  "zig run download_books.zig",
  "java DownloadBooks",
  "npx tsx download_books.ts"
]

runs = 3

results = {}

total_scripts = scripts.size
total_runs = total_scripts * runs
runs_done = 0
scripts.each_with_index do |script, index|
  puts "Testing script #{index + 1}/#{total_scripts}: #{script} (#{total_scripts - index - 1} scripts left)"
  times = []
  runs.times do |i|
    print "  Run #{i + 1}/#{runs} (total #{runs_done + 1}/#{total_runs})... "
    `rm -f book_*.txt`
    time = Benchmark.realtime { system(script) }
    times << time
    runs_done += 1
    puts "done (#{time.round(3)}s)"
  end
  avg = times.sum / times.size.to_f
  results[script] = avg
  puts "  Average: #{avg.round(3)}s"
end

display_names = {
  "python download_books.py" => "Python",
  "node download_books.js" => "JavaScript",
  "ruby download_books.rb" => "Ruby",
  "cargo run --bin download_books" => "Rust",
  "zig run download_books.zig" => "Zig",
  "java DownloadBooks" => "Java",
  "npx tsx download_books.ts" => "TypeScript"
}

File.open("newtimings.md", "w") do |f|
  f.puts "| Script | Time |"
  f.puts "|--------|------|"
  results.each do |script, avg|
    display = display_names[script] || script
    formatted = sprintf("0m%.3fs", avg)
    f.puts "| #{display} | #{formatted} |"
  end
end

puts "Results written to newtimings.md"