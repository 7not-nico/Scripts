#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'glimmer-dsl-libui'
require 'terminal-table'
require 'pastel'
require 'open3'

Book = Struct.new(:title, :author, :date, :url, :index, :image_url,
                   :isbn, :publisher, :language, :file_format, :file_size)

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

def extract_isbn(result)
  text = result.text
  # Look for ISBN patterns
  isbn_patterns = [
    /ISBN[-\s]?(\d{13})/i,
    /ISBN[-\s]?(\d{10})/i,
    /(\d{13})/,  # 13-digit numbers that might be ISBN
    /(\d{10})/   # 10-digit numbers that might be ISBN
  ]

  isbn_patterns.each do |pattern|
    match = text.match(pattern)
    return match[1] if match
  end
  nil
end

def extract_publisher(result)
  text = result.text
  # Look for publisher patterns
  publisher_patterns = [
    /Published by ([^\n,]+)/i,
    /Publisher: ([^\n,]+)/i,
    /Imprint: ([^\n,]+)/i
  ]

  publisher_patterns.each do |pattern|
    match = text.match(pattern)
    return match[1].strip if match
  end
  nil
end

def extract_language(result)
  text = result.text
  # Look for language indicators
  lang_patterns = {
    'English' => /english|en|us|uk/i,
    'Spanish' => /spanish|español|es/i,
    'French' => /french|français|fr/i,
    'German' => /german|deutsch|de/i,
    'Italian' => /italian|italiano|it/i,
    'Portuguese' => /portuguese|português|pt/i,
    'Chinese' => /chinese|中文|zh/i,
    'Japanese' => /japanese|日本語|ja/i,
    'Russian' => /russian|русский|ru/i
  }

  lang_patterns.each do |lang, pattern|
    return lang if text.match(pattern)
  end
  'Unknown'
end

def extract_file_format(result)
  text = result.text
  # Look for format indicators
  format_patterns = [
    /PDF/i,
    /EPUB/i,
    /MOBI/i,
    /AZW/i,
    /DJVU/i,
    /TXT/i,
    /RTF/i
  ]

  format_patterns.each do |pattern|
    return pattern.source.gsub('/i', '') if text.match(pattern)
  end
  'Unknown'
end

def extract_file_size(result)
  text = result.text
  # Look for size information
  size_patterns = [
    /(\d+(?:\.\d+)?)\s*(?:MB|GB|KB)/i,
    /Size:\s*(\d+(?:\.\d+)?)/i,
    /(\d+(?:\.\d+)?)\s*MB/i,
    /(\d+(?:\.\d+)?)\s*GB/i
  ]

  size_patterns.each do |pattern|
    match = text.match(pattern)
    return match[0] if match
  end
  nil
end

def parse_results(doc)
  results = doc.css('.flex.pt-3.pb-3')

  results.each_with_index.map do |result, i|
    title = extract_title(result)
    author = extract_author(result)
    date = extract_date(result)
    url = extract_url(result)
    image_url = extract_image_url(result)
    isbn = extract_isbn(result)
    publisher = extract_publisher(result)
    language = extract_language(result)
    file_format = extract_file_format(result)
    file_size = extract_file_size(result)

    # Skip ads
    next if title == "Your ad here." || author.nil?

    Book.new(title, author, date, url, i + 1, image_url,
             isbn, publisher, language, file_format, file_size)
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
    @last_cover_open = Time.now
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

    # Try ImageMagick display first (shows image in window)
    if system("display '#{selected_book.image_url}' 2>/dev/null &")
      self.status_message = "🖼️ Book cover displayed"
    # Fallback to browser
    elsif system("brave --app='#{selected_book.image_url}' 2>/dev/null &") ||
          system("xdg-open '#{selected_book.image_url}' 2>/dev/null &") ||
          system("open '#{selected_book.image_url}' 2>/dev/null &")
      self.status_message = "🖼️ Book cover opened in browser"
    else
      self.status_message = "❌ Failed to display book cover"
    end
  end

  def open_book_image_auto
    return unless selected_book && selected_book.image_url

    # Open silently in background
    system("brave --app='#{selected_book.image_url}' 2>/dev/null &") ||
    system("xdg-open '#{selected_book.image_url}' 2>/dev/null &") ||
    system("open '#{selected_book.image_url}' 2>/dev/null &")
  end

  def get_image_info(url)
    return nil unless url
    stdout, stderr, status = Open3.capture3("curl -s '#{url}' | identify -format '%wx%h %b' - 2>/dev/null | head -1")
    return nil unless status.success?
    stdout.strip
  rescue
    nil
  end

  def update_selection_display
    if selected_book
      info = "#{selected_book.title} • #{selected_book.language} • #{selected_book.file_format}"
      info += " • #{selected_book.file_size}" if selected_book.file_size
      self.status_message = info

      # Update cover preview
      if selected_book.image_url
        image_info = get_image_info(selected_book.image_url)
        if image_info
          @cover_display.text = "🖼️ Cover: #{image_info}\nClick 'View Cover' to display image"
        else
          @cover_display.text = "🖼️ Cover available\nClick 'View Cover' to display image"
        end
      else
        @cover_display.text = '❌ No cover available for this book'
      end
    else
      @cover_display.text = 'Select a book to preview cover'
    end
  end

  def truncate_text(text, max_length)
    return text if text.nil? || text.length <= max_length
    text[0..max_length-3] + "..."
  end

  def launch
    @current_selection = -1

    window('📚 Anna\'s Archive', 750, 550) {
      margined true

      vertical_box {
        # Search section
        group('Search') {
          vertical_box {
            horizontal_box {
              entry {
                text <=> [self, :search_query]
                stretchy true
              }
              button('🔍 Search') {
                on_clicked { search_books(search_query) }
              }
              button('🗑️ Clear') {
                on_clicked {
                  self.search_query = ""
                  self.books = []
                  self.selected_book = nil
                  self.status_message = "Ready"
                }
              }
            }
          }
        }

        # Results table with hover selection
        group('Books') {
          table {
            text_column('Title')
            text_column('Author')
            text_column('Year')
            text_column('Lang')
            text_column('Format')

            cell_rows <= [self, :books, on_read: ->(books) {
              books.map { |book| [
                truncate_text(book.title || 'Unknown', 25),
                truncate_text(book.author || 'Unknown', 18),
                book.date || 'Unknown',
                (book.language || 'UNK')[0..2],
                book.file_format || 'UNK'
              ]}
            }]

            # Table with enhanced selection feedback

            on_selection_changed do |table, selection|
              @current_selection = selection
              self.selected_book = books[selection] if selection >= 0
              update_selection_display
            end
          }
        }

        # Action buttons
        horizontal_box {
          button('📖 Open Book') {
            enabled <= [self, :selected_book, on_read: ->(book) { !book.nil? }]
            on_clicked { open_selected_book }
          }
          button('🖼️ View Cover') {
            enabled <= [self, :selected_book, on_read: ->(book) { book&.image_url }]
            on_clicked { open_book_image }
          }
          button('📊 Statistics') {
            on_clicked {
              count = books.size
              authors = books.map(&:author).compact.uniq.size
              languages = books.map(&:language).compact.uniq.size
              self.status_message = "#{count} books • #{authors} authors • #{languages} languages"
            }
          }
          button('❌ Quit') {
            on_clicked { exit(0) }
          }
        }

        # Cover preview area
        group('Cover Preview') {
          vertical_box {
            @cover_display = label { text 'Select a book to preview cover' }
          }
        }

        # Status bar
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