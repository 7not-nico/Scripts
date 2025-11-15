# Scripts Collection

A collection of useful scripts for various tasks, including CachyOS setup, web scraping, PDF searching, and browser modifications.

## CachyOS Scripts

Fast setup scripts for CachyOS Linux.

### Scripts

### `install_cachyos.sh`
Simple system installation with update-then-restart workflow.

### `complexver`
Advanced installation with CPU detection and repo optimization.

### `rate-mirrors.sh`
Mirror optimization + package installation (fish, octopi, zen-browser-bin).

### `brave-modify.sh`
Modify Brave browser Local State to enable experimental features and launch browser.

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
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas_archive_online.sh)

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
ruby annas-archive-search/annas_search.rb 'search term'
# Or online: bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/annas_archive_online.sh) 'search term' [number]

# Search PDFs
ruby pdf-search/pdf_search.rb 'topic'  # Requires BRAVE_API_KEY

# Modify Brave Local State (Ruby)
ruby brave-script/modify_local_state.rb

# Install CachyOS repo
awk -f cachyos-repo/install-repo.awk /etc/pacman.conf
```

## Features

- Auto system updates
- Mirror optimization with cachyos-rate-mirrors
- Package installation with paru
- KISS principle - simple, direct, stupid

## Anna's Archive Search

Scripts for searching books on Anna's Archive.

- `annas_search.rb`: Search and list books with title/author/date, open Brave webapp on selection
- `annas_archive_online.sh`: Online runner for the search script

Run locally: `ruby annas-archive-search/annas_search.rb 'search term' [number]`

Displays formatted list (e.g., 1. "Title" by Author (Date)), selects number, opens Brave webapp.

Run online: `./annas_archive_online.sh 'search term' [number]`

## PDF Search

Scripts for searching and downloading PDFs from the web using Brave Search API or Selenium.

- `pdf_search.rb`: Auto-download all PDF results
- `pdf_selector.rb`: Select which PDFs to download
- `brave_selenium_search.rb`: Selenium-based search without API key

Run: `ruby pdf-search/pdf_search.rb 'term'` (requires Brave API key)

## Brave Browser Script

Modify Brave browser's Local State to enable experimental features.

- `modify_local_state.rb`: Enable features and launch browser

Run: `ruby brave-script/modify_local_state.rb`

## CachyOS Repository Management

AWK scripts for managing CachyOS repositories.

- `install-repo.awk`: Install standard CachyOS repo
- `install-v4-repo.awk`: Install x86-64-v4 optimized repo
- `install-znver4-repo.awk`: Install Zen4 optimized repo
- `remove-repo.awk`: Remove CachyOS repo

Run: `awk -f cachyos-repo/install-repo.awk /etc/pacman.conf`
