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
    books.each do |book|
      date = book[:date] || "Unknown Date"
      prefix = book[:filetype] ? "[#{filetype_color(book[:filetype])}] " : ""
      title = truncate(book[:title], title_max).bold
      author = truncate(book[:author], author_max).cyan
      date_colored = date.gray
      puts "#{prefix}#{book[:index]}. \"#{title}\" by #{author} (#{date_colored})"
    end
  end
end