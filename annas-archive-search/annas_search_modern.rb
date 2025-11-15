#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'glimmer-dsl-libui'
require 'terminal-table'
require 'pastel'

Book = Struct.new(:title, :author, :date, :url, :index, :image_url)

def extract_title(result)
  result_text = result.text.strip
  lines = result_text.split("\n").map(&:strip).reject(&:empty?)
  lines[1] || lines[0]
end

def extract_author(result)
  author_element = result.css('a[href*="/search?q="]').first
  author_element&.text&.strip
end

def extract_date(result)
  result_text = result.text.strip
  date_match = result_text.match(/(\w+ \d{1,2}, \d{4}|\b(19[0-9]{2}|20[0-2][0-9])\b)/)
  date_match ? date_match[1] || date_match[2] : nil
end

def extract_url(result)
  link_element = result.at_css('a')
  link_element ? "https://annas-archive.org#{link_element['href']}" : nil
end

def extract_image_url(result)
  # Look for book cover images in the result
  img_element = result.at_css('img')
  if img_element && img_element['src']
    src = img_element['src']
    # Convert relative URLs to absolute
    src.start_with?('http') ? src : "https://annas-archive.org#{src}"
  else
    nil
  end
end

def parse_results(doc)
  results = doc.css('.flex.pt-3.pb-3')
  results.each_with_index.map do |result, i|
    title = extract_title(result)
    author = extract_author(result)
    date = extract_date(result)
    url = extract_url(result)
    image_url = extract_image_url(result)

    # Skip ads
    next if title == "Your ad here." || author.nil?

    Book.new(title, author, date, url, i + 1, image_url)
  end.compact
end

# Table display is now handled by Glimmer GUI components

def parse_selection(input, book_count)
  return (0...book_count).to_a if input.downcase == 'all'

  input.split(',').map(&:strip).map(&:to_i).map { |n| n - 1 }.select { |n| n >= 0 && n < book_count }
end

def open_browser(book)
  puts "Opening Brave for: #{book[:title]}"
  url = book[:url]
  if system("brave --app='#{url}' 2>/dev/null")
    puts "Opened successfully."
  else
    puts "Failed to open Brave. Try: brave-browser --app='#{url}'"
  end
end

class AnnaSearchApp
  include Glimmer

  attr_accessor :search_query, :books, :selected_book, :status_message, :is_searching, :search_count

  def initialize
    @search_query = ""
    @books = []
    @selected_book = nil
    @status_message = "🔍 Ready to search for books"
    @is_searching = false
    @search_count = 0
  end

  def search_books(query)
    return if query.strip.empty?

    self.is_searching = true
    self.status_message = "🔎 Searching Anna's Archive for '#{query}'..."
    self.search_count += 1

    url = "https://annas-archive.org/search?q=#{URI.encode_www_form_component(query)}"

    begin
      doc = Nokogiri::HTML(URI.open(url))
      self.books = parse_results(doc)
      book_count = books.size
      self.status_message = case book_count
                           when 0 then "❌ No books found for '#{query}'"
                           when 1 then "📖 Found 1 book"
                           else "📚 Found #{book_count} books"
                           end
    rescue => e
      self.status_message = "❌ Search failed: #{e.message}"
      self.books = []
    ensure
      self.is_searching = false
    end
  end

  def open_selected_book
    return unless selected_book

    self.status_message = "🌐 Opening '#{selected_book.title}' in browser..."
    book_data = {
      title: selected_book.title,
      author: selected_book.author,
      date: selected_book.date,
      url: selected_book.url,
      index: selected_book.index
    }

    if open_browser(book_data)
      self.status_message = "✅ Successfully opened '#{selected_book.title}'"
    else
      self.status_message = "⚠️ Failed to open browser. Check Brave installation."
    end
  end

  def open_book_image
    return unless selected_book && selected_book.image_url

    self.status_message = "🖼️ Opening book cover..."
    system("brave --app='#{selected_book.image_url}' 2>/dev/null") ||
    system("xdg-open '#{selected_book.image_url}' 2>/dev/null") ||
    system("open '#{selected_book.image_url}' 2>/dev/null")

    self.status_message = "🖼️ Book cover opened"
  end

  def launch
    window('📚 Anna\'s Archive', 700, 500) {
      margined true

      vertical_box {
        # Compact header
        horizontal_box {
          label('🔍') { stretchy false }
          label('Book Search') { stretchy true }
          label("#{search_count}🔎") { stretchy false }
        }

        # Compact search bar
        horizontal_box {
          entry {
            text <=> [self, :search_query]
            stretchy true
          }
          button('Search') {
            on_clicked { search_books(search_query) }
          }
          button('Clear') {
            on_clicked {
              self.search_query = ""
              self.books = []
              self.selected_book = nil
              self.status_message = "Cleared"
            }
          }
        }

        # Results table - more compact
        table {
          text_column('Title')
          text_column('Author')
          text_column('Date')
          text_column('Cover')

          cell_rows <= [self, :books, on_read: ->(books) {
            books.map { |book| [
              book.title || 'Unknown',
              book.author || 'Unknown',
              book.date || 'Unknown',
              book.image_url ? '🖼️' : '❌'
            ]}
          }]

          on_selection_changed do |table, selection|
            self.selected_book = books[selection] if selection >= 0
          end

          stretchy true
        }

        # Compact action bar
        horizontal_box {
          button('📖 Open') {
            enabled <= [self, :selected_book, on_read: ->(book) { !book.nil? }]
            on_clicked { open_selected_book }
          }
          button('🖼️ Cover') {
            enabled <= [self, :selected_book, on_read: ->(book) { book&.image_url }]
            on_clicked { open_book_image }
          }
          button('📊 Stats') {
            on_clicked {
              count = books.size
              authors = books.map(&:author).compact.uniq.size
              self.status_message = "#{count} books, #{authors} authors"
            }
          }
          button('❌ Quit') {
            on_clicked { exit(0) }
          }
        }

        # Status label
        label { text <=> [self, :status_message] }
      }
    }.show
  end
end

# Main execution
if ARGV.empty?
  # Modern GUI-like TUI mode
  app = AnnaSearchApp.new
  app.launch
else
  # CLI mode for backward compatibility
  puts "Usage: ruby annas_search_modern.rb"
  puts "Run without arguments for modern GUI-like TUI mode"
  exit 1
end