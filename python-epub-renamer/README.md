# Python Epub Renamer

A simple, fast, and KISS-compliant epub file renamer that formats files as `title - author.epub`.

## Features

- **Performant**: Fast execution using Python standard library only
- **KISS-Compliant**: Single file, minimal dependencies, clear code
- **No Redundancies**: Single purpose, efficient implementation
- **Cross-platform**: Works on Linux, macOS, Windows
- **Curl-executable**: Run directly from GitHub URLs

## Usage

### Direct execution
```bash
python3 epub_renamer.py book.epub
```

### Via curl (recommended)
```bash
curl -L https://raw.githubusercontent.com/user/repo/main/epub_renamer.py | python3 - book.epub
```

### Multiple files
```bash
python3 epub_renamer.py book1.epub book2.epub book3.epub
```

### Dry run (preview changes)
```bash
python3 epub_renamer.py --dry-run *.epub
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