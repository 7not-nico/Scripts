# PDF Search Scripts

This folder contains Ruby scripts for searching and downloading PDFs from the web.

## Scripts

- `pdf_search.rb`: Searches PDFs using Brave API and downloads all results automatically.
- `pdf_selector.rb`: Searches PDFs using Brave API, displays a list, and lets the user select which to download.
- `brave_selenium_search.rb`: Searches PDFs using Selenium to scrape Brave search results directly (no API key), displays list, and downloads selected.

## Usage

- **API Scripts**: Get free Brave API key from https://api.search.brave.com/, set `export BRAVE_API_KEY=your_key`, run `ruby pdf-search/pdf_search.rb 'term'` or `ruby pdf-search/pdf_selector.rb 'term'`.
- **Selenium Script**: Install `selenium-webdriver` gem and geckodriver, run `ruby pdf-search/brave_selenium_search.rb 'term'`.

## Fixes and Changes

- **Initial Setup**: Used Brave Search API for reliability.
- **Syntax Errors**: Used `ruby -c` instead of `bash -n` for Ruby scripts.
- **API Switch**: Tried Google API for "best results," but reverted to Brave for simplicity (fewer setup steps).
- **Scraping with Nokogiri**: Attempted static scraping, but kept API to avoid potential blocks.
- **Segmentation**: Created separate scripts for auto vs. selective downloads to keep minimal.
- **KISS Principle**: Simplified code (e.g., filename sanitization to one line), removed redundancies.
- **Browser Launch**: Opened browser for API signup.
- **Selenium Addition**: Added slower but self-contained alternative for comparison; used Firefox driver.
- **Selector Errors**: Inspected Brave HTML to get correct CSS selectors (e.g., `.snippet` for results).

## Dependencies

- Ruby
- For API scripts: net/http, json, open-uri, fileutils (standard Ruby libraries).
- For Selenium script: `gem install selenium-webdriver`, and geckodriver (install via package manager or download from https://github.com/mozilla/geckodriver/releases).

## Notes

- Downloads to `output` folder.
- Selenium is slower but no key needed; use for light searches.