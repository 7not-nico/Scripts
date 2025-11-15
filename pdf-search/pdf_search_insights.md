# PDF Search Script Insights

## Overview
We developed a Ruby script (`brave_pdf_search.rb`) to perform headless PDF searches using the Brave browser via Selenium WebDriver. The goal was to search for PDFs without using APIs, automating the browser silently.

## Key Steps and Insights
1. **Gem Installation Challenges**:
   - Initially installed `selenium-webdriver` and `webdrivers`.
   - Encountered version conflicts: `selenium-webdriver-4.38.0` conflicted with `webdrivers` requiring `< 4.11`.
   - Resolution: Selenium 4.11+ includes built-in driver management, so `webdrivers` is unnecessary. Updated to compatible Selenium version and removed `webdrivers`.

2. **Brave Browser Setup**:
   - Located Brave binary at `/usr/bin/brave` on Linux.
   - Configured Selenium for headless mode with appropriate options to avoid sandbox issues.

3. **Script Functionality**:
   - Navigates to `https://search.brave.com/`, enters query with `filetype:pdf`, submits, and extracts PDF links.
   - Downloads PDFs using `curl` to `output/` directory.
   - Selector `a[data-ved]` may need adjustment for Brave's DOM structure.

4. **Testing**:
   - Ran with query 'ruby programming'.
   - Script executed without errors, but no output printed (likely due to headless mode).
   - Checked `output/` directory: empty, indicating no PDFs were found or downloaded.
   - Likely issue: CSS selector `a[data-ved]` does not match Brave search result links. Brave's DOM may differ from Google's.
   - Potential fixes: Inspect Brave search page manually, update selector (e.g., to `.result a` or similar), or add debug prints for found links.

## Lessons Learned
- Selenium version management is critical; prefer latest versions for built-in features.
- Headless browser automation requires careful option tuning for stability.
- Web scraping via browser can be fragile due to changing site structures.
- Always test in non-headless mode first for debugging.

## Fixes Applied
1. **Gem Version Conflicts**:
   - Error: `selenium-webdriver-4.38.0` conflicted with `webdrivers` requiring `< 4.11`.
   - Fix: Uninstalled conflicting `selenium-webdriver-4.38.0`, installed `selenium-webdriver >=4.11` (which has built-in driver management), and removed `webdrivers` gem from the script (no longer needed).
   - Result: Gems load without conflicts.

2. **Script Execution Issues**:
   - Error: No PDFs downloaded despite successful run.
   - Analysis: CSS selector `a[data-ved]` doesn't match Brave's search result links (designed for Google).
   - Planned Fix (to apply in build mode): Inspect Brave search HTML, update selector (e.g., to `.result a` or equivalent), add debug prints for URLs, re-test.

## Future Improvements
- Refine CSS selectors for accurate link extraction.
- Add error handling for network issues or invalid downloads.
- Implement retries or alternative download methods.
- Test on different systems/OS for Brave path variations.