class Display
  def self.truncate(str, len)
    str.length > len ? "#{str[0...len]}..." : str
  end

  def self.display_books(books, title_max, author_max)
    puts "Found books:"
    books.each do |book|
      date = book[:date] || "Unknown Date"
      prefix = book[:filetype] ? "[#{book[:filetype]}] " : ""
      title = truncate(book[:title], title_max)
      author = truncate(book[:author], author_max)
      puts "#{prefix}#{book[:index]}. \"#{title}\" by #{author} (#{date})"
    end
  end
end