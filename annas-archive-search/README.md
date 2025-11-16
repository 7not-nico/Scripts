# Anna's Archive Search Scripts

These scripts search for books on Anna's Archive using fast web scraping with Nokogiri.

## Script

- `annas_search.rb`: Searches Anna's Archive, displays list of books with titles, authors, dates, and filetypes (e.g., PDF, EPUB), prompts for selection, prints `brave-browser --app 'url'` command for manual execution.

## Usage

Run: `ruby annas-archive-search/annas_search.rb 'search term' [number]`

Displays list, select numbers, prints `brave-browser --app 'url'` to copy and run manually.

## Fixes and Changes

- **Scraping Setup**: Used Nokogiri for fast static HTML parsing (no Selenium/browser).
- **Selector Errors**: Inspected Anna's Archive HTML to get correct CSS selectors (e.g., `.flex.pt-3.pb-3` for results, `h3 a` for titles/links). Updated torrent selector to `/dyn/small_file/torrents/` for current site structure.
- **Title Extraction**: Improved to get clean book titles from `h3 a` elements, falling back to `result.text.strip.split("\n").first` for robustness.
- **Error Handling**: Added rescues for network failures, missing elements; skips invalid results.
- **Input Reading Fix**: Changed `gets` to `STDIN.gets` to avoid ARGF reading from command-line arguments as files, ensuring interactive input works correctly. Added nil check for piped input.
- **Browser Opening**: Initially tried system calls with `xdg-open` and `brave`, but switched to printing `brave-browser --app` command for manual execution to avoid GUI/environment issues. Added webapp mode for dedicated window.
- **Command Correction**: Used `brave-browser` for correct terminal invocation, added `--app` for webapp mode.
- **Automation**: Added optional selection argument for non-interactive usage (e.g., `ruby annas_search.rb 'term' 1`).
- **KISS Principle**: Consolidated to single script, removed redundancies, kept simple and functional.
- **Book Type Display**: Added extraction of book filetype (e.g., PDF, EPUB) from search results using regex pattern `/ · ([A-Z]{3,4}) · /` on result text. Displays filetype in brackets after date if available, e.g., "(2004) [PDF]". Avoids showing for missing types to prevent redundancy.
- **Code Refactoring**: Introduced `truncate` helper function to eliminate duplication in title/author truncation. Optimized extraction functions to compute `result.text.strip` once per result and pass to text-based extractors, reducing redundant operations.

## Dependencies

- Ruby
- `nokogiri` gem: `gem install nokogiri`
- `open-uri` and `fileutils` (standard Ruby libraries)

## Notes

- No API key needed.
- Prints `brave-browser --app 'url'` for manual execution in webapp mode.
- Fast search with Nokogiri.
- Handles first page of results only.
- Optional selection arg for automation.