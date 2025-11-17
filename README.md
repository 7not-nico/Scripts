# Scripts Collection

A comprehensive collection of useful scripts for system administration, web scraping, file management, and browser automation. All scripts follow the KISS principle - simple, direct, and minimal complexity.

## Project Structure

- **CachyOS Scripts** - System installation and repository management
- **Web Scraping** - Anna's Archive search, PDF downloading
- **Browser Tools** - Brave browser modification and automation
- **File Utilities** - EPUB renaming (Go, Python implementations)
- **Download Tools** - Project Gutenberg multi-language downloader
- **Desktop Apps** - Anna's Archive desktop application (Tauri)

## CachyOS Scripts

Fast setup scripts for CachyOS Linux with automatic optimization.

### Scripts

- **`install_cachyos.sh`** - Simple system installation with update-then-restart workflow
- **`complexver`** - Advanced installation with CPU detection and repo optimization
- **`rate-mirrors.sh`** - Mirror optimization + package installation (fish, octopi, zen-browser-bin)
- **`brave-modify.sh`** - Modify Brave browser Local State to enable experimental features

## Online Execution

Click the copy icon (📋) in the top-right of each code block:

```bash
# Simple installation
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/install_cachyos.sh)
```

```bash
# Complex installation
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/complexver)
```

```bash
# Mirror setup only
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/rate-mirrors.sh)
```

```bash
# Modify Brave Local State
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/brave-modify.sh)
```

```bash
# Search Anna's Archive
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas_archive_online.sh) 'search term' [number]

```

## Quick Start

### CachyOS Setup
```bash
# Simple installation
./install_cachyos.sh

# Complex installation
./complexver

# Mirror setup only
./rate-mirrors.sh

# Modify Brave Local State
./brave-modify.sh
```

### Other Scripts
```bash
# Search Anna's Archive
ruby annas-archive-search/annas_search.rb 'search term' [number]
# Or online: bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas_archive_online.sh) 'search term' [number]

# Search and download all PDFs (requires BRAVE_API_KEY)
ruby pdf-search/pdf_search.rb 'topic'

# Search PDFs and select which to download (requires BRAVE_API_KEY)
ruby pdf-search/pdf_selector.rb 'topic'

# Search PDFs with Selenium (no API key needed)
ruby pdf-search/brave_selenium_search.rb 'topic'

# Modify Brave Local State (Ruby)
ruby brave-script/modify_local_state.rb

# Install CachyOS repo (auto-detects CPU)
sudo ./cachyos-repo/cachyos-repo.sh --install
# Or manually: awk -f cachyos-repo/install-repo.awk /etc/pacman.conf
```

## Features

- Auto system updates
- Mirror optimization with cachyos-rate-mirrors
- Package installation with paru
- KISS principle - simple, direct, stupid

## Anna's Archive Search

Fast web scraping scripts for searching books on Anna's Archive with caching and performance optimizations.

- **`annas_search.rb`**: Search with cached results, filetype display, and automated browser launching
- **`annas_archive_online.sh`**: Online runner for the search script

Features:
- File-based caching (1-hour TTL) for repeated searches
- Filetype display (PDF, EPUB) in search results
- Optional selection argument for automation
- Fast Nokogiri-based HTML parsing

Run locally: `ruby annas-archive-search/annas_search.rb 'search term' [number]`
Run online: `bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas_archive_online.sh) 'search term' [number]`

## PDF Search

Comprehensive PDF search and download tools with multiple search methods.

- **`pdf_search.rb`**: Auto-download all PDF results using Brave Search API
- **`pdf_selector.rb`**: Interactive selection of PDFs to download (API-based)
- **`brave_selenium_search.rb`**: Selenium-based search without API key requirement
- **`content_sorter.rb`**: Organize downloaded PDFs by content analysis

Features:
- API and Selenium-based search options
- Batch download with progress tracking
- Content-based file organization
- Automatic duplicate detection

Run: `ruby pdf-search/pdf_search.rb 'term'` (API key required) or `ruby pdf-search/brave_selenium_search.rb 'term'` (no key needed)

## Brave Browser Tools

Browser automation and optimization tools for Brave browser.

- **`modify_local_state.rb`**: Enable experimental features (Vulkan, GPU rasterization, etc.)
- **`brave-modify.sh`**: Bash wrapper for the Ruby script

Features:
- Vulkan rendering with ANGLE
- GPU rasterization and zero-copy uploads
- Skia renderer for PDFs
- Automatic backup creation
- Safe modification with rollback option

Run: `ruby brave-script/modify_local_state.rb` or `./brave-modify.sh`

## CachyOS Repository Management

Advanced repository management with automatic CPU optimization detection.

- **`cachyos-repo.sh`**: Main bash script to install/remove repos (auto-detects CPU)
- **`install-repo.awk`**: AWK script for standard CachyOS (x86-64-v3) repo
- **`install-v4-repo.awk`**: AWK script for x86-64-v4 optimized repo
- **`install-znver4-repo.awk`**: AWK script for Zen4 optimized repo
- **`remove-repo.awk`**: AWK script to remove CachyOS repos

Features:
- Automatic CPU ISA level detection
- Keyring and mirrorlist installation
- Safe backup and rollback
- Multi-architecture support

Run: `sudo ./cachyos-repo/cachyos-repo.sh --install` (recommended) or use individual AWK scripts

## EPUB File Renamers

High-performance tools to rename EPUB files using metadata extraction.

### Go Implementation
- **`go-epub-renamer/`**: Compiled binary with minimal memory usage
- Single binary deployment, cross-platform support
- Performance: <200ms per file, <10MB peak memory

### Python Implementation  
- **`python-epub-renamer/`**: Lightweight Python script using standard library
- Cross-platform with curl-executable support
- No external dependencies required

Usage (Go): `./epub-renamer book.epub` or via curl installer
Usage (Python): `python3 epub_renamer.py book.epub`

Both formats: `title - author.epub` with dry-run support

## Project Gutenberg Downloader

Multi-language implementation for downloading books from Project Gutenberg.

### Supported Languages
- **Ruby**: `ruby download_books.rb`
- **Python**: `python download_books.py` (requires requests)
- **JavaScript**: `node download_books.js`
- **TypeScript**: `ts-node download_books.ts`
- **Rust**: `cargo run` 
- **Java**: `javac DownloadBooks.java && java DownloadBooks`
- **Zig**: `zig run download_books.zig`

Features:
- Parallel downloading for performance
- Downloads books 1-100 as `book_{id}.txt`
- Skips existing files automatically
- Error handling for invalid IDs

## Anna's Archive Desktop Application

Cross-platform desktop application built with Tauri for searching Anna's Archive.

- **Frontend**: HTML/CSS/JavaScript
- **Backend**: Rust with Tauri framework
- **Features**: Native desktop experience, fast search, integrated browser

Installation: Build from source with `npm install && npm run tauri build`

## Development Guidelines

### Code Style
- **Bash**: `set -e`, `snake_case()` functions, `local` variables
- **Error Handling**: Clear exit codes (0 success, 1 error)
- **Package Management**: Use `paru-bin` with `--needed --noconfirm` flags
- **Testing**: Syntax check with `bash -n` for scripts, `ruby -c` for Ruby

### Common Fixes
- **Ruby `gets` Error**: Use `STDIN.gets` instead of `gets` for interactive input
- **Web Scraping**: Update CSS selectors when site structure changes
- **API Integration**: Handle rate limits and network failures gracefully
