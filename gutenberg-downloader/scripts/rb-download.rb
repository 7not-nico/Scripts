require 'net/http'
require 'thread'
require 'etc'

class GutenbergDownloader
  TITLE_LIMIT = 40
  AUTHOR_LIMIT = 20
  BASE_URL = "https://www.gutenberg.org"

  def initialize
    @completed = [0]
    @mutex = Mutex.new
    Dir.mkdir("output") unless Dir.exist?("output")
  end

  def process_all(books)
    total = books.size
    queue = Queue.new
    books.each { |id| queue << id }

    threads = Etc.nprocessors.times.map do
      Thread.new { process_queue(queue, total) }
    end

    threads.each(&:join)
    puts "\nDownload complete."
  end

  private

  def sanitize_filename(name)
    name.gsub(/[^0-9A-Za-z\s\-]/, '').strip
  end

  def extract_metadata(xml, id)
    title = xml[/<dcterms:title>(.*?)<\/dcterms:title>/, 1] || "Book #{id}"
    author = xml[/<pgterms:name>(.*?)<\/pgterms:name>/, 1] || "Unknown Author"
    year = xml[/<dcterms:issued>(\d{4})/, 1]

    title = "#{title[4..-1]} (The)" if title&.start_with?("The ")
    [title, author, year]
  end

  def format_filename(title, author, year)
    sanitized = "#{sanitize_filename(title)} - #{sanitize_filename(author)}"
    year ? "#{sanitized} (#{year}).epub" : "#{sanitized}.epub"
  end

  def truncate_text(text, limit)
    text.length > limit ? "#{text[0..limit-3]}..." : text
  end

  def format_display(title, author, year, id)
    t = truncate_text(title, TITLE_LIMIT)
    a = truncate_text(author, AUTHOR_LIMIT)
    year_info = year ? " (#{year})" : ""
    "Downloading '#{t}' by #{a}#{year_info} - ID: #{id}"
  end

  def fetch_metadata(id)
    uri = URI("#{BASE_URL}/ebooks/#{id}.rdf")
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.path)
      while response.code == "302"
        response = http.get(URI(response['location']).path)
      end
      response.code == "200" ? response.body : nil
    end
  rescue
    nil
  end

  def process_queue(queue, total)
    while id = queue.pop(true) rescue nil
      process_book(id, total)
    end
  end

  def process_book(id, total)
    return unless xml = fetch_metadata(id)
    title, author, year = extract_metadata(xml, id)

    filename = "output/#{format_filename(title, author, year)}"
    return if File.exist?(filename)

    puts format_display(title, author, year, id)
    download_epub(id, filename)
    update_progress(total)
  end

  def download_epub(id, filename)
    uri = URI("#{BASE_URL}/cache/epub/#{id}/pg#{id}.epub")
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.path)
      File.write(filename, response.body) if response.code == "200"
    end
  rescue
    puts "Skipped ID #{id}: Download failed"
  end

  def update_progress(total)
    @mutex.synchronize do
      @completed[0] += 1
      return unless @completed[0] % 10 == 0 || @completed[0] == total
      progress_bar = "█" * (@completed[0] * 50 / total)
      printf("\r[%-50s] %d/%d (%.1f%%)", progress_bar, @completed[0], total, @completed[0] * 100.0 / total)
      STDOUT.flush
    end
  end
end

# Main execution
downloader = GutenbergDownloader.new
ids = (1..90000).to_a.sample(100)
downloader.process_all(ids)
