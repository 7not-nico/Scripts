#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'tty-prompt'
require 'tty-table'
require 'tty-spinner'
require 'pastel'

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

    { title: title, author: author, date: date, url: url, index: i + 1 }
  end.compact
end

def display_books_table(books)
  pastel = Pastel.new
  table = TTY::Table.new(header: [
    pastel.bold('#'),
    pastel.bold('Title'),
    pastel.bold('Author'),
    pastel.bold('Date')
  ])

  books.each do |book|
    truncated_title = book[:title] && book[:title].length > 50 ? book[:title][0..47] + "..." : book[:title]
    truncated_author = book[:author] && book[:author].length > 30 ? book[:author][0..27] + "..." : book[:author]
    date = book[:date] || "Unknown Date"

    table << [
      book[:index].to_s,
      truncated_title || "Unknown Title",
      truncated_author || "Unknown Author",
      date
    ]
  end

  puts table.render(:unicode, padding: [0, 1])
end

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

def search_books(query)
  url = "https://annas-archive.org/search?q=#{URI.encode_www_form_component(query)}"

  spinner = TTY::Spinner.new("Searching for '#{query}'... :spinner", format: :pulse_2)
  spinner.auto_spin

  begin
    doc = Nokogiri::HTML(URI.open(url))
    spinner.success("Search completed!")
  rescue => e
    spinner.error("Search failed!")
    puts "Failed to fetch search page: #{e.message}"
    exit 1
  end

  books = parse_results(doc)
  books
end

def interactive_search
  prompt = TTY::Prompt.new
  pastel = Pastel.new

  puts pastel.bold.blue("🔍 Anna's Archive TUI Search")
  puts "=" * 50

  loop do
    search_query = prompt.ask("Search for books:", required: true) do |q|
      q.modify :strip
    end

    break if search_query.nil? || search_query.empty?

    books = search_books(search_query)

    if books.empty?
      puts pastel.red("No books found for '#{search_query}'")
      next
    end

    puts pastel.green("Found #{books.size} books:")
    display_books_table(books)

    choices = books.map do |book|
      truncated_title = book[:title] && book[:title].length > 40 ? book[:title][0..37] + "..." : book[:title]
      truncated_author = book[:author] && book[:author].length > 25 ? book[:author][0..22] + "..." : book[:author]
      {
        name: "#{book[:index]}. #{truncated_title} by #{truncated_author}",
        value: book[:index] - 1
      }
    end

    choices << { name: "Search again", value: :search_again }
    choices << { name: "Quit", value: :quit }

    selection = prompt.select("Choose a book to open:", choices, per_page: 10)

    case selection
    when :search_again
      next
    when :quit
      break
    else
      book = books[selection]
      open_browser(book)
    end
  end
end

# Main execution
if ARGV.empty?
  # Interactive TUI mode
  interactive_search
else
  # CLI mode for backward compatibility
  puts "Usage: ruby annas_search_tui.rb"
  puts "Run without arguments for interactive TUI mode"
  exit 1
end