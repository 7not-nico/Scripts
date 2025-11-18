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