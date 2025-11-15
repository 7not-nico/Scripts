# Anna's Archive Search Scripts

These scripts search for books on Anna's Archive using fast web scraping with Nokogiri.

## Scripts

- `annas_search.rb`: Displays list of books, opens browser for selected books.
- `annas_direct_search.rb`: Displays list of books, opens browser for selected books.

## Usage

Run: `ruby annas-archive-search/annas_search.rb 'search term'` or `ruby annas-archive-search/annas_direct_search.rb 'search term'`

Both display a list, prompt for selection, and open default browser to the book's page for manual download.

## Fixes and Changes

- **Scraping Setup**: Used Nokogiri for fast static HTML parsing (no Selenium/browser).
- **Selector Errors**: Inspected Anna's Archive HTML to get correct CSS selectors (e.g., `.flex.pt-3.pb-3` for results, `a[href*="/dyn/small_file/torrents/"]` for downloads).
- **Format Extraction**: Added regex to parse book format from page text (e.g., "Format: PDF") for filename extension; defaults to 'unknown' if not found.
- **Error Handling**: Added rescues for network failures, missing elements; skips invalid results.
- **Segmentation**: Created separate scripts for torrent vs. direct downloads to keep minimal.
- **Filename Sanitization**: Applied KISS principle with simple regex for clean filenames.
- **Input Reading Fix**: Changed `gets` to `STDIN.gets` to avoid ARGF reading from command-line arguments as files, ensuring interactive input works correctly.

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