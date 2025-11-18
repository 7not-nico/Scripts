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

# Download and extract the entire directory
temp_dir=$(mktemp -d)
if ! curl -sL https://github.com/7not-nico/Scripts/archive/main.tar.gz | tar -xz -C "$temp_dir" --strip-components=1 "Scripts-main/annas-archive-search/"; then
  echo "Error: Failed to download and extract script from GitHub. Check network or URL."
  rm -rf "$temp_dir"
  exit 1
fi

# Check if extraction succeeded
if [ ! -f "$temp_dir/annas-archive-search/annas_search.rb" ]; then
  echo "Error: Script extraction failed - annas_search.rb not found."
  rm -rf "$temp_dir"
  exit 1
fi

# Run with ruby
cd "$temp_dir/annas-archive-search"
ruby annas_search.rb "$search_term" "$selection"

# Clean up
cd - > /dev/null
rm -rf "$temp_dir"