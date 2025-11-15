#!/bin/bash

# Anna's Archive Search Online Runner
# Downloads and runs the Ruby script from GitHub

if [ $# -eq 0 ]; then
  echo "Usage: $0 'search term' [selection]"
  echo "If selection is provided, automatically selects that number."
  exit 1
fi

search_term="$1"
selection="$2"

# Download to temp file
temp_script=$(mktemp)
curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas-archive-search/annas_search.rb > "$temp_script"

# Run with ruby
if [ -n "$selection" ]; then
  echo "$selection" | ruby "$temp_script" "$search_term"
else
  ruby "$temp_script" "$search_term"
fi

# Clean up
rm "$temp_script"