require 'open-uri'
require 'thread'

queue = Queue.new
(1..100).each { |id| queue << id }

workers = 5
threads = workers.times.map do
  Thread.new do
    while id = queue.pop(true) rescue nil
      if File.exist?("book_#{id}.txt")
        next
      end
      url = "https://www.gutenberg.org/cache/epub/#{id}/pg#{id}.txt"
      begin
        URI.open(url) do |response|
          content = response.read
          File.write("book_#{id}.txt", content)
        end
      rescue => e
        # Silent fail for simplicity
      end
    end
  end
end

threads.each(&:join)
puts "Download complete."
