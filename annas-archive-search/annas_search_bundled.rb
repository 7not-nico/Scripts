#!/usr/bin/env ruby

begin
require 'json'
require 'fileutils'
require 'digest'
require 'colorize'
require 'nokogiri'
require 'open-uri'
rescue LoadError => e
  puts "Missing required gem: #{e.message}"
  puts "Install with: gem install nokogiri colorize"
  exit 1
end

# Inline library code
class Errors
  def self.handle(message, exit_code = 1)
    puts "Error: #{message}"
    exit exit_code
  end

  def self.handle_network(error)
    case error
    when OpenURI::HTTPError
      case error.message
      when /^4\d\d/
        handle("HTTP #{error.message} - client error, check your request")
      when /^500/
        handle("HTTP #{error.message} - server error, try again later")
      when /^502/
        handle("HTTP #{error.message} - server gateway error, service temporarily unavailable")
      when /^503/
        handle("HTTP #{error.message} - service unavailable, server overloaded")
      when /^504/
        handle("HTTP #{error.message} - gateway timeout, try again later")
      else
        handle("HTTP #{error.message} - site may be down or blocking requests")
      end
    when SocketError
      handle("Network connection failed - check your internet connection and DNS settings")
    when Net::ReadTimeout
      handle("Request timeout - server took too long to respond, try again")
    when Net::OpenTimeout
      handle("Connection timeout - couldn't connect to server, check network")
    when Errno::ECONNREFUSED
      handle("Connection refused - server is not accepting connections")
    when Errno::EHOSTUNREACH
      handle("Host unreachable - server cannot be reached")
    when Errno::ENETUNREACH
      handle("Network unreachable - check your internet connection")
    when OpenSSL::SSL::SSLError
      handle("SSL error - secure connection failed")
    else
      handle("Failed to fetch results - #{error.message} (try again later)")
    end
  end

  def self.handle_cache(error, operation)
    case error
    when Errno::ENOENT
      # Cache file doesn't exist, this is normal
      return false
    when Errno::EACCES
      puts "Warning: Cache permission denied during #{operation}"
      return false
    when JSON::ParserError
      puts "Warning: Cache corrupted during #{operation}, clearing cache"
      return true # Signal to clear cache
    else
      puts "Warning: Cache error during #{operation}: #{error.message}"
      return false
    end
  end
end

class Config
  class << self
    def cache
      {
        dir: File.expand_path('~/.cache/annas_search'),
        ttl: 3600,  # 1 hour
        cleanup_probability: 0.1,  # 10% chance to cleanup on each run
        max_size_mb: 50,  # Maximum cache size in MB
        max_files: 1000   # Maximum number of cache files
      }
    end

    def display
      {
        title_max_len: 50,
        author_max_len: 30
      }
    end

    def network
      {
        open_timeout: 10,
        read_timeout: 30,
        base_url: 'https://annas-archive.org'
      }
    end

    def browsers
      {
        fallbacks: ['brave --app', 'firefox --new-window', 'chromium --app'],
        cmd: ENV['BROWSER_COMMAND']
      }
    end

    def debug
      ENV['DEBUG'] == '1'
    end

    def parsing
      {
        result_selector: '.flex.pt-3.pb-3',
        author_selector: 'a[href*="/search?q="]',
        date_regex: /\b(19[0-9]{2}|20[0-2][0-9])\b/,
        filetype_regex: / · ([A-Z0-9]{2,6}) · | \.([a-z]{3,4})\b|\(([A-Z0-9]{3,4})\)|\[([A-Z0-9]{3,4})\]| - ([a-z]{3,4})\)| \(([A-Z0-9]{3,4})/
      }
    end

    def validate
      begin
        FileUtils.mkdir_p(cache[:dir])
      rescue => e
        Errors.handle("Failed to create cache directory #{cache[:dir]}: #{e.message}")
      end

      # Validate timeouts are reasonable
      Errors.handle("Invalid timeout values") if network[:open_timeout] <= 0 || network[:read_timeout] <= 0

      # Validate cache settings
      Errors.handle("Invalid cache TTL") if cache[:ttl] <= 0
      Errors.handle("Invalid cleanup probability") unless (0..1).include?(cache[:cleanup_probability])

      # Validate display lengths
      Errors.handle("Invalid display lengths") if display[:title_max_len] <= 0 || display[:author_max_len] <= 0
    end
  end
end

class Cache
  def self.get_file(search, cache_dir)
    "#{cache_dir}/#{Digest::SHA256.hexdigest(search)}.json"
  end

  def self.load(cache_file, ttl)
    return nil unless File.exist?(cache_file) && (Time.now - File.mtime(cache_file)) < ttl

    begin
      JSON.parse(File.read(cache_file), symbolize_names: true)
    rescue JSON::ParserError
      nil
    end
  end

  def self.save(cache_file, books)
    return if books.empty?

    File.write(cache_file, JSON.generate(books))
    File.utime(Time.now, Time.now, cache_file) # Update access time for LRU
  end

  def self.cleanup(cache_dir, ttl, probability, max_files = 1000, max_size_mb = 50)
    return unless Dir.exist?(cache_dir) && rand < probability

    # Remove expired files first
    cleanup_expired(cache_dir, ttl)

    # Then enforce size limits
    enforce_size_limits(cache_dir, max_files, max_size_mb)
  end

  def self.cleanup_expired(cache_dir, ttl)
    now = Time.now
    Dir.each_child(cache_dir) do |file|
      next unless file.end_with?('.json')
      filepath = File.join(cache_dir, file)
      File.delete(filepath) if (now - File.mtime(filepath)) >= ttl
    end
  end

  def self.enforce_size_limits(cache_dir, max_files = 1000, max_size_mb = 50)
    cache_files = Dir.glob(File.join(cache_dir, '*.json'))
    return if cache_files.empty?

    # Check file count limit
    if cache_files.size > max_files
      files_by_access = cache_files.sort_by { |f| File.mtime(f) }
      files_to_remove = files_by_access.first(cache_files.size - max_files)
      files_to_remove.each { |f| File.delete(f) if File.exist?(f) }
      cache_files -= files_to_remove
    end

    # Check size limit
    max_size_bytes = max_size_mb * 1024 * 1024
    total_size = cache_files.sum { |f| File.exist?(f) ? File.size(f) : 0 }

    if total_size > max_size_bytes
      files_by_access = cache_files.sort_by { |f| File.mtime(f) }
      current_size = total_size

      files_by_access.each do |file|
        break if current_size <= max_size_bytes
        next unless File.exist?(file)

        file_size = File.size(file)
        File.delete(file)
        current_size -= file_size
      end
    end
  end

  def self.get_stats(cache_dir)
    return { files: 0, size_mb: 0 } unless Dir.exist?(cache_dir)

    cache_files = Dir.glob(File.join(cache_dir, '*.json'))
    return { files: 0, size_mb: 0 } if cache_files.empty?

    total_size = cache_files.sum { |f| File.exist?(f) ? File.size(f) : 0 }

    {
      files: cache_files.size,
      size_mb: (total_size.to_f / 1024 / 1024).round(2)
    }
  end
end

class Network
  def self.build_search_url(query, base_url)
    "#{base_url}/search?q=#{URI.encode_www_form_component(query)}"
  end

  def self.fetch_with_retry(url, open_timeout, read_timeout, max_retries = 3)
    retries = 0

    begin
      fetch(url, open_timeout, read_timeout)
    rescue OpenURI::HTTPError => e
      if retries < max_retries && (e.message.start_with?('5') || e.message == '429')
        retries += 1
        delay = 2 ** retries
        sleep(delay)
        retry
      else
        raise
      end
    rescue SocketError, Net::ReadTimeout, Net::OpenTimeout => e
      if retries < max_retries
        retries += 1
        delay = 2 ** retries
        sleep(delay)
        retry
      else
        raise
      end
    end
  end

  def self.fetch(url, open_timeout, read_timeout)
    URI.open(url, open_timeout: open_timeout, read_timeout: read_timeout)
  end

  def self.fetch_html(url, open_timeout, read_timeout)
    Nokogiri::HTML(fetch_with_retry(url, open_timeout, read_timeout))
  end
end

class Parser
  def self.extract_raw_results(doc, result_selector)
    doc.css(result_selector).map do |result|
      {
        text: result.text.strip,
        element: result
      }
    end
  end
end

class BookBuilder
  def self.extract_filetype(text)
    # Try multiple strategies to find filetypes

    # Strategy 1: Standard Anna's Archive pattern · TYPE ·
    match = text.match(/ · ([A-Z0-9]{2,6}) · /)
    return match[1] if match

    # Strategy 2: Bracketed formats [PDF], [EPUB]
    match = text.match(/\[([A-Z0-9]{3,6})\]/)
    return match[1] if match

    # Strategy 3: Parenthesized formats (PDF), (EPUB)
    match = text.match(/\(([A-Z0-9]{3,6})\)/)
    return match[1] if match

    # Strategy 4: File extensions in paths .pdf, .epub, .mobi, .txt, .zip
    match = text.match(/\.([a-z0-9]{3,4})\b/i)
    return match[1].upcase if match && ['pdf', 'epub', 'mobi', 'txt', 'zip', 'azw3', 'djvu', 'chm', 'lit', 'cbr', 'cbz'].include?(match[1].downcase)

    # Strategy 5: Format mentions "PDF format", "EPUB version", etc.
    format_keywords = ['pdf', 'epub', 'mobi', 'txt', 'zip', 'azw3', 'djvu', 'chm', 'lit', 'cbr', 'cbz']
    format_keywords.each do |fmt|
      if text.match?(/\b#{fmt}\b/i)
        return fmt.upcase
      end
    end

    # Strategy 6: Look for common filetype indicators in the text
    if text.match?(/\bformat:?\s*([a-z0-9]{3,4})/i)
      match = text.match(/\bformat:?\s*([a-z0-9]{3,4})/i)
      fmt = match[1].downcase
      return fmt.upcase if ['pdf', 'epub', 'mobi', 'txt', 'zip'].include?(fmt)
    end

    nil
  end

  def self.build_book(raw_result, index, author_selector, date_regex, filetype_regex, base_url)
    text = raw_result[:text]
    return nil if text.include?("Your ad here.")

    lines = text.split("\n").map(&:strip).reject(&:empty?)
    title = lines[1] || lines[0]

    author_link = raw_result[:element].at_css(author_selector)
    author = author_link&.text&.strip
    return nil unless author

    date_match = text.match(date_regex)
    filetype = extract_filetype(text)

    book_link = raw_result[:element].at_css('a.js-vim-focus')
    url = book_link ? "#{base_url}#{book_link['href']}" : nil

    {
      title: title,
      author: author,
      date: date_match ? date_match[0] : nil,
      url: url,
      index: index + 1,
      filetype: filetype
    }
  end

  def self.build_books(raw_results, author_selector, date_regex, filetype_regex, base_url)
    raw_results.each_with_index.filter_map do |raw_result, index|
      build_book(raw_result, index, author_selector, date_regex, filetype_regex, base_url)
    end
  end
end

class Display
  def self.truncate(str, len)
    str.length > len ? "#{str[0...len]}..." : str
  end

  def self.filetype_color(ft)
    case ft
    when 'PDF' then ft.green
    when 'EPUB' then ft.blue
    when 'MOBI' then ft.yellow
    when 'LIT' then ft.magenta
    when 'CHM' then ft.cyan
    when 'DJVU' then ft.red
    when 'ZIP' then ft.light_blue
    else ft.white
    end
  end

  def self.display_books(books, title_max, author_max)
    puts "Found books:".bold
    books.each_with_index do |book, display_index|
      date = book[:date] || "Unknown Date"
      prefix = book[:filetype] ? "[#{filetype_color(book[:filetype])}] " : ""
      title = truncate(book[:title], title_max).bold
      author = truncate(book[:author], author_max).cyan
      date_colored = date.gray
      display_number = display_index + 1
      puts "#{prefix}#{display_number}. \"#{title}\" by #{author} (#{date_colored})"
    end
  end
end

class Browser
  @@available_browsers = []

  def self.open(book, fallbacks, debug, title_max)
    return unless book[:url]
    fallbacks.each do |browser|
      next unless available?(browser, debug)
      # Parse browser command into array and append URL
      cmd_parts = browser.split + [book[:url]]
      puts "DEBUG: Trying browser command: #{cmd_parts.join(' ')}" if debug
      success = system(*cmd_parts)
      puts "DEBUG: Browser command success: #{success}" if debug
      if success
        puts "Opened: #{Display.truncate(book[:title], title_max)}"
        return
      end
    end
    puts "Failed to open browser for: #{Display.truncate(book[:title], title_max)}"
  end

  def self.available?(browser_cmd, debug)
    return true if @@available_browsers.include?(browser_cmd)
    # Use 'which' to check if browser executable exists
    browser_exe = browser_cmd.split.first
    available = system("which #{browser_exe} >/dev/null 2>&1")
    puts "DEBUG: Browser '#{browser_cmd}' available: #{available}" if debug
    @@available_browsers << browser_cmd if available
    available
  end
end

class Input
  def self.validate_search_query(query)
    return false if query.nil? || query.strip.empty?

    # Check for potentially dangerous characters
    dangerous_patterns = [
      /[<>]/,           # HTML tags
      /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/,  # Control characters
      /[;&|`$(){}\[\]]/, # Shell injection characters
    ]

    dangerous_patterns.each do |pattern|
      return false if query.match?(pattern)
    end

    # Length validation
    return false if query.length > 200

    true
  end

  def self.parse_selection(input, count)
    return (0...count).to_a if input.downcase == 'all'
    input.split(',').map { |n| n.strip.to_i - 1 }.select { |n| n.between?(0, count - 1) }
  end

  def self.parse_selection_by_position(input, books)
    return (0...books.size).to_a if input.downcase == 'all'

    user_selections = input.split(',').map { |n| n.strip.to_i }
    result = []

    user_selections.each do |pos|
      # Convert 1-based display position to 0-based array index
      array_index = pos - 1
      if array_index.between?(0, books.size - 1)
        result << array_index
      end
    end

    result
  end

  def self.get(selection)
    return selection if selection
    puts "Enter numbers (comma-separated or 'all'):"
    STDIN.gets&.chomp&.strip || ''
  end
end

Config.validate

# Main execution
Cache.cleanup(Config.cache[:dir], Config.cache[:ttl], Config.cache[:cleanup_probability])
if ARGV.empty?
  puts "Usage: ruby annas_search.rb 'search string' [selection]"
  puts "  selection: optional number(s) to open (comma-separated or 'all')"
  puts "  Examples:"
  puts "    ruby annas_search.rb 'ruby programming'"
  puts "    ruby annas_search.rb 'ruby programming' 1"
  puts "    ruby annas_search.rb 'ruby programming' '1,3,5'"
  exit 1
end

search = ARGV[0]
selection = ARGV[1]

# Validate search query
unless Input.validate_search_query(search)
  puts "Error: Invalid search query"
  puts "Query must be 1-200 characters and not contain special characters like < > ; & | ` $ ( ) { } [ ]"
  exit 1
end

url = Network.build_search_url(search, Config.network[:base_url])
cache_file = Cache.get_file(search, Config.cache[:dir])

# Try cache first
begin
  books = Cache.load(cache_file, Config.cache[:ttl])
rescue => e
  if Errors.handle_cache(e, "load")
    # Clear corrupted cache
    File.delete(cache_file) if File.exist?(cache_file)
    books = nil
  else
    books = nil
  end
end

# Fetch if no cache or expired
unless books
  begin
    puts "Searching Anna's Archive..."
    doc = Network.fetch_html(url, Config.network[:open_timeout], Config.network[:read_timeout])
    raw_results = Parser.extract_raw_results(doc, Config.parsing[:result_selector])
    books = BookBuilder.build_books(raw_results, Config.parsing[:author_selector], Config.parsing[:date_regex], Config.parsing[:filetype_regex], Config.network[:base_url])
    begin
      Cache.save(cache_file, books)
    rescue => e
      Errors.handle_cache(e, "save")
    end
    puts "Found #{books.size} books"
   rescue => e
    Errors.handle_network(e)
  end
end

if books.empty?
  puts "No books found."
  exit 0
end

Display.display_books(books, Config.display[:title_max_len], Config.display[:author_max_len])

# Handle selection
input = Input.get(selection)
exit 0 if input.empty?

selections = Input.parse_selection_by_position(input, books)
browser_cmd = Config.browsers[:cmd] || Config.browsers[:fallbacks].first
selections.each { |i| Browser.open(books[i], Config.browsers[:fallbacks], Config.debug, Config.display[:title_max_len]) } if selections.any?