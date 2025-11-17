# Go Epub Renamer

High-performance, compiled EPUB file renamer written in Go, designed for speed and reliability with minimal resource usage.

## Overview

This Go application provides lightning-fast EPUB file renaming by extracting metadata from the EPUB's internal structure. It formats files as `title - author.epub` with robust error handling and cross-platform compatibility.

## Features

- **High Performance**: Compiled binary with sub-second processing per file
- **Minimal Memory**: <10MB peak memory usage
- **KISS Principle**: Clean, focused implementation using only standard library
- **Cross-Platform**: Single binary works on Linux, macOS, Windows
- **Curl-Executable**: Direct execution from GitHub URLs via installer script
- **Safe Operations**: Won't overwrite existing files, comprehensive error handling

## Usage

### Direct Execution
```bash
# Single file
./epub-renamer book.epub

# Multiple files
./epub-renamer book1.epub book2.epub book3.epub

# All EPUB files in directory
./epub-renamer *.epub
```

### Via Curl (Recommended)
```bash
# Direct execution from GitHub
curl -L https://raw.githubusercontent.com/7not-nico/Scripts/main/go-epub-renamer/scripts/install.sh | bash -s -- book.epub
```

### Advanced Options
```bash
# Dry run (preview changes without renaming)
./epub-renamer --dry-run *.epub

# Verbose output
./epub-renamer --verbose book.epub

# Help
./epub-renamer --help
```

## Requirements

- Go 1.21+ (for building)
- No runtime dependencies (single binary)

## Building

```bash
# Clone repository
git clone https://github.com/user/go-epub-renamer.git
cd go-epub-renamer

# Build for current platform
go build -o epub-renamer ./cmd/epub-renamer

# Cross-compile for multiple platforms
make build-all
```

## How it works

1. Parses epub's ZIP structure to find `META-INF/container.xml`
2. Extracts content.opf path from container
3. Parses Dublin Core metadata from content.opf
4. Sanitizes title and author for filesystem compatibility
5. Renames file to format: `title - author.epub`

## Error handling

- Clear error messages for common issues
- Graceful handling of corrupted epub files
- Fallback parsing for malformed XML
- Safe renaming (won't overwrite existing files)

## Performance

- **Startup time**: <100ms
- **Per file processing**: <200ms
- **Memory usage**: <10MB peak
- **Binary size**: ~5MB (statically linked)

## Examples

```bash
# Rename a single file
$ ./epub-renamer "War and Peace - Leo Tolstoy.epub"
Processing: War and Peace - Leo Tolstoy.epub
Renamed: War and Peace - Leo Tolstoy.epub -> War and Peace - Leo Tolstoy.epub

# Process multiple files
$ ./epub-renamer *.epub
Processing: book1.epub
Renamed: book1.epub -> Pride and Prejudice - Jane Austen.epub
Processing: book2.epub
Renamed: book2.epub -> 1984 - George Orwell.epub

# Dry run to preview
$ ./epub-renamer --dry-run *.epub
Processing: book1.epub
Would rename: book1.epub -> Pride and Prejudice - Jane Austen.epub
Processing: book2.epub
Would rename: book2.epub -> 1984 - George Orwell.epub
```

## Project Principles

- **Performant**: Optimized Go code with efficient memory usage
- **KISS-Compliant**: Simple architecture, clear separation of concerns
- **No Redundancies**: Single implementation path, no duplicate functionality

## Architecture

```
cmd/epub-renamer/     # Main application
├── main.go          # CLI entry point
pkg/epub/            # Epub parsing logic
├── parser.go        # Metadata extraction
pkg/renamer/         # File renaming logic
├── renamer.go       # Filename generation and renaming
scripts/             # Deployment scripts
├── install.sh       # Curl-based installer
```