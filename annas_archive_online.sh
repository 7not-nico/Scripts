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

# Download to temp file
temp_script=$(mktemp)
curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas-archive-search/annas_search.rb > "$temp_script"

# Check if download succeeded
if [ ! -s "$temp_script" ]; then
  echo "Error: Failed to download script from GitHub. Check network or URL."
  rm "$temp_script"
  exit 1
fi

# Run with ruby
ruby "$temp_script" "$search_term" "$selection"

# Clean up
rm "$temp_script"