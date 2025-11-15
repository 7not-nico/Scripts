#!/bin/bash

# Anna's Archive Search Online Runner
# Downloads and runs the Ruby script from GitHub

if [ $# -eq 0 ]; then
  echo "Usage: $0 'search term'"
  exit 1
fi

# Download the script and run with ruby
curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas-archive-search/annas_search.rb | ruby - "$@"