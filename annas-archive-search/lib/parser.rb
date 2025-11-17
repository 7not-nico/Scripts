class Parser
  def self.extract_book_data(result, index, author_selector, date_regex, filetype_regex, base_url)
    text = result.text.strip
    return nil if text.include?("Your ad here.")

    lines = text.split("\n").map(&:strip).reject(&:empty?)
    title = lines[1] || lines[0]

    author_link = result.at_css(author_selector)
    author = author_link&.text&.strip
    return nil unless author

    date_match = text.match(date_regex)
    filetype_match = text.match(filetype_regex)

    book_link = result.at_css('a.js-vim-focus')
    url = book_link ? "#{base_url}#{book_link['href']}" : nil

    {
      title: title,
      author: author,
      date: date_match ? date_match[0] : nil,
      url: url,
      index: index + 1,
      filetype: filetype_match ? filetype_match[1] : nil
    }
  end

  def self.parse_books(doc, result_selector, author_selector, date_regex, filetype_regex, base_url)
    doc.css(result_selector).each_with_index.filter_map do |result, index|
      extract_book_data(result, index, author_selector, date_regex, filetype_regex, base_url)
    end
  end
end