#!/bin/bash

# Anna's Archive Search Online Runner
# Downloads and runs the enhanced Ruby script from GitHub (with improved parsing)

if [ $# -eq 0 ]; then
  echo "Usage: $0 'search term' [selection]"
  echo "If selection is provided, automatically selects that number."
  exit 1
fi

search_term="$1"
selection="$2"

# Download bundled script (single file, ultra-minimal overhead)
temp_script=$(mktemp)
if ! curl -s "https://raw.githubusercontent.com/7not-nico/Scripts/main/annas-archive-search/annas_search_bundled.rb" -o "$temp_script"; then
  echo "Error: Failed to download bundled script from GitHub."
  rm "$temp_script"
  exit 1
fi

# Run with ruby
ruby "$temp_script" "$search_term" "$selection"

# Clean up
cd - > /dev/null
rm -rf "$temp_dir"