# Python Epub Renamer

Lightweight, fast, and KISS-compliant EPUB file renamer written in Python, using only the standard library for maximum portability.

## Overview

This Python script provides reliable EPUB file renaming by parsing the EPUB's metadata. It formats files as `title - author.epub` with intelligent fallbacks for missing metadata and cross-platform filesystem compatibility.

## Features

- **High Performance**: Fast execution with minimal resource usage
- **Zero Dependencies**: Uses only Python standard library
- **KISS Principle**: Single file, clear code, focused functionality
- **Cross-Platform**: Works on Linux, macOS, Windows
- **Curl-Executable**: Direct execution from GitHub URLs
- **Intelligent Fallbacks**: Handles missing metadata gracefully

## Usage

### Direct Execution
```bash
# Single file
python3 epub_renamer.py book.epub

# Multiple files
python3 epub_renamer.py book1.epub book2.epub book3.epub

# All EPUB files in directory
python3 epub_renamer.py *.epub
```

### Via Curl (Recommended)
```bash
# Direct execution from GitHub
curl -L https://raw.githubusercontent.com/7not-nico/Scripts/main/python-epub-renamer/epub_renamer.py | python3 - book.epub
```

### Advanced Options
```bash
# Dry run (preview changes without renaming)
python3 epub_renamer.py --dry-run *.epub

# Verbose output
python3 epub_renamer.py --verbose book.epub

# Help
python3 epub_renamer.py --help
```

## Requirements

- Python 3.6+
- No external dependencies (uses standard library only)

## How it works

1. Extracts metadata from epub's `content.opf` file
2. Sanitizes title and author for filesystem compatibility
3. Renames file to format: `title - author.epub`
4. Handles missing metadata gracefully with fallbacks

## Error handling

- Clear error messages for common issues
- Graceful handling of corrupted epub files
- Fallback to filename parsing when metadata is missing
- Safe renaming (won't overwrite existing files)

## Examples

```bash
# Rename a single file
$ python3 epub_renamer.py "War and Peace - Leo Tolstoy.epub"
Renamed: War and Peace - Leo Tolstoy.epub -> War and Peace - Leo Tolstoy.epub

# Process multiple files
$ python3 epub_renamer.py *.epub
Processing: book1.epub
Renamed: book1.epub -> Pride and Prejudice - Jane Austen.epub
Processing: book2.epub
Renamed: book2.epub -> 1984 - George Orwell.epub

# Dry run to preview
$ python3 epub_renamer.py --dry-run *.epub
Would rename: book1.epub -> Pride and Prejudice - Jane Austen.epub
Would rename: book2.epub -> 1984 - George Orwell.epub
```

## Project Principles

- **Performant**: Optimized for speed and low memory usage
- **KISS-Compliant**: Simple, maintainable code with clear purpose
- **No Redundancies**: Single implementation path, no duplicate functionality