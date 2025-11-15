#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'glimmer-dsl-libui'
require 'terminal-table'
require 'pastel'

Book = Struct.new(:title, :author, :date, :url, :index)

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

def parse_results(doc)
  results = doc.css('.flex.pt-3.pb-3')
  results.each_with_index.map do |result, i|
    title = extract_title(result)
    author = extract_author(result)
    date = extract_date(result)
    url = extract_url(result)

    # Skip ads
    next if title == "Your ad here." || author.nil?

    Book.new(title, author, date, url, i + 1)
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

  def launch
    window('📚 Anna\'s Archive - Modern TUI', 900, 700) {
      margined true

      vertical_box {
        # Header section
        horizontal_box {
          label('🔍') {
            stretchy false
          }
          label('Anna\'s Archive Book Search') {
            stretchy true
          }
          label("Searches: #{search_count}") {
            stretchy false
          }
        }

        # Search section
        group('🔎 Search Books') {
          margined true
          vertical_box {
            horizontal_box {
              entry {
                text <=> [self, :search_query]
                stretchy true
              }

              button('🔍 Search') {
                on_clicked do
                  search_books(search_query)
                end
              }

              button('🗑️ Clear') {
                on_clicked do
                  self.search_query = ""
                  self.books = []
                  self.selected_book = nil
                  self.status_message = "🧹 Cleared search and results"
                end
              }
            }
          }
        }

        # Results section
        group('📚 Search Results') {
          margined true
          vertical_box {
            table {
              text_column('📖 Title')
              text_column('👤 Author')
              text_column('📅 Date')

              cell_rows <= [self, :books, on_read: ->(books) {
                books.map { |book| [
                  book.title || '❓ Unknown Title',
                  book.author || '❓ Unknown Author',
                  book.date || '❓ Unknown Date'
                ]}
              }]

              on_selection_changed do |table, selection|
                self.selected_book = books[selection] if selection >= 0
                if selected_book
                  self.status_message = "📋 Selected: #{selected_book.title} by #{selected_book.author}"
                end
              end
            }
          }
        }

        # Action buttons
        horizontal_box {
          button('🌐 Open Book') {
            enabled <= [self, :selected_book, on_read: ->(book) { !book.nil? }]
            on_clicked do
              open_selected_book
            end
          }

          button('📊 Statistics') {
            on_clicked do
              book_count = books.size
              author_count = books.map(&:author).compact.uniq.size
              self.status_message = "📊 #{book_count} books from #{author_count} authors"
            end
          }

          button('❌ Quit') {
            on_clicked do
              exit(0)
            end
          }
        }

        # Status bar with better styling
        group('📢 Status') {
          margined true
          vertical_box {
            label {
              text <=> [self, :status_message]
              stretchy true
            }
          }
        }
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