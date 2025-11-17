require 'net/http'
require 'net/http'
require 'thread'
require 'etc'

def sanitize_filename(name)
  name.gsub(/[^0-9A-Za-z\s\-]/, '').strip
end

def download_book(id, mutex, completed, total)
  title = "Book #{id}"
  author = "Unknown Author"
  begin
    uri = URI("https://www.gutenberg.org/ebooks/#{id}.rdf")
    rdf_response = Net::HTTP.get_response(uri)
    while rdf_response.code == "302"
      location = rdf_response['location']
      rdf_response = Net::HTTP.get_response(URI(location))
    end
    if rdf_response.code == "200"
      xml = rdf_response.body
      title_match = xml.match(/<dcterms:title>(.*?)<\/dcterms:title>/m)
      title = title_match[1] if title_match
      author_match = xml.match(/<dcterms:creator>.*?<pgterms:name>(.*?)<\/pgterms:name>/m)
      author = author_match[1] if author_match
      issued_match = xml.match(/<dcterms:issued[^>]*>(.*?)<\/dcterms:issued>/m)
      year = issued_match ? issued_match[1].split('-')[0] : nil
    else
      # Skip if RDF not found
      return
    end
  rescue
    return
  end

  filename = year ? "#{sanitize_filename(title)} - #{sanitize_filename(author)} (#{year}).epub" : "#{sanitize_filename(title)} - #{sanitize_filename(author)}.epub"
  return if File.exist?(filename)

  puts "Downloading '#{truncated_title}' by #{truncated_author}#{year ? " (#{year})" : ""} - ID: #{id}"
  begin
    epub_response = Net::HTTP.get_response(URI("https://www.gutenberg.org/cache/epub/#{id}/pg#{id}.epub"))
    if epub_response.code == "200"
      File.write(filename, epub_response.body)
    else
      puts "Skipped ID #{id}: EPUB not available"
    end
  rescue
    puts "Skipped ID #{id}: EPUB not available"
  end
    if rdf_response.code == "200"
      xml = rdf_response.body
      title_match = xml.match(/<dcterms:title>(.*?)<\/dcterms:title>/m)
      title = title_match[1] if title_match
      if title && title.start_with?("The ")
        title = title[4..-1] + " (The)"
      end
      author_match = xml.match(/<dcterms:creator>.*?<pgterms:name>(.*?)<\/pgterms:name>/m)
      author = author_match[1] if author_match
      issued_match = xml.match(/<dcterms:issued[^>]*>(.*?)<\/dcterms:issued>/m)
      year = issued_match ? issued_match[1].split('-')[0] : nil
    end
  rescue
  end

  filename = year ? "#{sanitize_filename(title)} - #{sanitize_filename(author)} (#{year}).epub" : "#{sanitize_filename(title)} - #{sanitize_filename(author)}.epub"
  return if File.exist?(filename)

  truncated_title = title.length > 40 ? title[0..37] + "..." : title
  truncated_author = author.length > 20 ? author[0..17] + "..." : author
  puts "Downloading '#{truncated_title}' by #{truncated_author}#{year ? " (#{year})" : ""} - ID: #{id}"
  epub_response = http_get("https://www.gutenberg.org/cache/epub/#{id}/pg#{id}.epub") rescue {code: "500", body: ""}
  if epub_response[:code] == "200"
    File.write(filename, epub_response[:body])
  else
    puts "Skipped ID #{id}: EPUB not available"
  end

  mutex.synchronize do
    completed[0] += 1
    printf("\r[%-50s] %d/%d (%.1f%%)", "█" * (completed[0] * 50 / total), completed[0], total, completed[0] * 100.0 / total)
    STDOUT.flush
  end
end

completed = [0]
total = 100
mutex = Mutex.new
queue = Queue.new

# Generate 100 random unique book IDs from 1 to 90000
ids = (1..90000).to_a.sample(100)
ids.each { |id| queue << id }

num_threads = Etc.nprocessors
threads = []
num_threads.times do
  threads << Thread.new do
    while id = queue.pop(true) rescue nil
      download_book(id, mutex, completed, total)
    end
  end
end

threads.each(&:join)
puts "\nDownload complete."
