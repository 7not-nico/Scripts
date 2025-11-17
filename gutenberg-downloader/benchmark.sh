#!/bin/bash
export TIMEFORMAT="%R"
for run in 4 5 6 7 8; do
  rm -f book_*.txt
  for script_cmd in "python download_books.py" "node download_books.js" "ruby download_books.rb" "cargo run --bin download_books" "zig run download_books.zig" "java DownloadBooks" "npx tsx download_books.ts"; do
    script_name="$script_cmd"
    time_output=$( { time $script_cmd; } 2>&1 )
    time_val=$(echo "$time_output" | tail -1)
    formatted_time=$(printf "0m%.3fs" $time_val)
    echo "$run,$script_name,$formatted_time" >> data.csv
  done
done