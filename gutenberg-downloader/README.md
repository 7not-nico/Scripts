# Gutenberg Downloader

Scripts to download the first 100 books from Project Gutenberg in Ruby, Python, Zig, Java, JavaScript, Rust, and TypeScript.

## Usage

- Ruby: `ruby download_books.rb`
- Python: `python download_books.py` (requires `requests`)
- Zig: `zig run download_books.zig` (may need API fixes)
- Java: `javac DownloadBooks.java && java DownloadBooks`
- JavaScript: `node download_books.js`
- Rust: `cargo run` (in directory with Cargo.toml)
- TypeScript: `ts-node download_books.ts` (requires ts-node)

Each downloads books 1-100 as `book_{id}.txt`, skipping existing files.

## Requirements

- Ruby/Python/Zig/Java/Node.js/Rust/TypeScript
- Internet connection
- For Python: `pip install requests`
- For Rust: Cargo
- For TypeScript: ts-node

## Notes

- Some IDs may not be books, but scripts try.
- Plain text from Gutenberg cache.
- All performant (parallel), KISS, avoid redundancies.