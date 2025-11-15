# Anna's Archive Search Scripts

These scripts search for books on Anna's Archive using fast web scraping with Nokogiri.

## Script

- `annas_search.rb`: Searches Anna's Archive, displays list of books, prompts for selection, prints `brave` command with URL for manual execution.

## Usage

Run: `ruby annas-archive-search/annas_search.rb 'search term'`

Displays list, select numbers, prints `brave 'url'` to copy and run manually.

## Fixes and Changes

- **Scraping Setup**: Used Nokogiri for fast static HTML parsing (no Selenium/browser).
- **Selector Errors**: Inspected Anna's Archive HTML to get correct CSS selectors (e.g., `.flex.pt-3.pb-3` for results, `h3 a` for titles/links).
- **Title Extraction**: Improved to get clean book titles from `h3 a` elements.
- **Error Handling**: Added rescues for network failures, missing elements; skips invalid results.
- **Input Reading Fix**: Changed `gets` to `STDIN.gets` to avoid ARGF reading from command-line arguments as files, ensuring interactive input works correctly.
- **Browser Opening**: Initially tried system calls, but switched to printing `brave` command for manual execution to avoid GUI issues.
- **KISS Principle**: Consolidated to single script, removed redundancies.

## Dependencies

- Ruby
- `nokogiri` gem: `gem install nokogiri`
- `open-uri` and `fileutils` (standard Ruby libraries)

## Notes

- No API key needed.
- Torrent script: Downloads .torrent files for torrent client.
- Direct script: Downloads book files directly (may be slow/large).
- Fast search with Nokogiri.
- Handles first page of results only.