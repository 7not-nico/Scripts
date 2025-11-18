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

# Create temp directory structure
temp_dir=$(mktemp -d)
mkdir -p "$temp_dir/lib"

# Download main script and all required library files
base_url="https://raw.githubusercontent.com/7not-nico/Scripts/main/annas-archive-search"

# Download main script
if ! curl -s "$base_url/annas_search.rb" -o "$temp_dir/annas_search.rb"; then
  echo "Error: Failed to download main script from GitHub."
  rm -rf "$temp_dir"
  exit 1
fi

# Download library files
lib_files="config.rb errors.rb cache.rb network.rb parser.rb book_builder.rb display.rb browser.rb input.rb"
for lib_file in $lib_files; do
  if ! curl -s "$base_url/lib/$lib_file" -o "$temp_dir/lib/$lib_file"; then
    echo "Error: Failed to download lib/$lib_file from GitHub."
    rm -rf "$temp_dir"
    exit 1
  fi
done

# Verify downloads
if [ ! -f "$temp_dir/annas_search.rb" ]; then
  echo "Error: Main script download failed."
  rm -rf "$temp_dir"
  exit 1
fi

# Run with ruby
cd "$temp_dir"
ruby annas_search.rb "$search_term" "$selection"

# Clean up
cd - > /dev/null
rm -rf "$temp_dir"