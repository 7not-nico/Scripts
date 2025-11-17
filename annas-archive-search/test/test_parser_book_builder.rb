#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'
require 'nokogiri'

require_relative '../lib/parser'
require_relative '../lib/book_builder'

class TestParser < Minitest::Test
  def setup
    @html = <<~HTML
      <div class="flex pt-3 pb-3">
        <div>
          <a href="/search?q=author1">Author One</a>
          <a href="/book/123">Book Title</a>
          <span>2023</span>
          <span> · PDF · </span>
        </div>
      </div>
      <div class="flex pt-3 pb-3">
        <div>
          <a href="/search?q=author2">Author Two</a>
          <a href="/book/456">Another Book</a>
          <span>2022</span>
          <span> · EPUB · </span>
        </div>
      </div>
      <div class="flex pt-3 pb-3">
        <div>
          Your ad here.
        </div>
      </div>
    HTML
    
    @doc = Nokogiri::HTML(@html)
    @result_selector = '.flex.pt-3.pb-3'
  end

  def test_extract_raw_results_returns_correct_count
    results = Parser.extract_raw_results(@doc, @result_selector)
    assert_equal 3, results.length
  end

  def test_extract_raw_results_includes_text_and_element
    results = Parser.extract_raw_results(@doc, @result_selector)
    
    results.each do |result|
      assert result.key?(:text)
      assert result.key?(:element)
      assert_kind_of String, result[:text]
      assert_kind_of Nokogiri::XML::Element, result[:element]
    end
  end

  def test_extract_raw_results_strips_text
    results = Parser.extract_raw_results(@doc, @result_selector)
    
    results.each do |result|
      assert_equal result[:text], result[:text].strip
    end
  end
end

class TestBookBuilder < Minitest::Test
  def setup
    @html = <<~HTML
      <div class="flex pt-3 pb-3">
        <div>
          <a href="/search?q=test+author">Test Author</a>
          <a class="js-vim-focus" href="/book/123">Test Book Title</a>
          <span>2023</span>
          <span> · PDF · </span>
        </div>
      </div>
    HTML
    
    @doc = Nokogiri::HTML(@html)
    @raw_result = {
      text: @doc.css('.flex.pt-3.pb-3').first.text.strip,
      element: @doc.css('.flex.pt-3.pb-3').first
    }
    
    @author_selector = 'a[href*="/search?q="]'
    @date_regex = /\b(19[0-9]{2}|20[0-2][0-9])\b/
    @filetype_regex = / · ([A-Z]{3,4}) ·/
    @base_url = 'https://annas-archive.org'
  end

  def test_build_book_creates_valid_book
    book = BookBuilder.build_book(@raw_result, 0, @author_selector, @date_regex, @filetype_regex, @base_url)
    
    refute_nil book
    assert_equal "Test Book Title", book[:title]
    assert_equal "Test Author", book[:author]
    assert_equal "2023", book[:date]
    assert_equal "PDF", book[:filetype]
    assert_equal "https://annas-archive.org/book/123", book[:url]
    assert_equal 1, book[:index]
  end

  def test_build_book_returns_nil_for_ad_content
    ad_result = {
      text: "Your ad here.",
      element: @doc.css('.flex.pt-3.pb-3').first
    }
    
    book = BookBuilder.build_book(ad_result, 0, @author_selector, @date_regex, @filetype_regex, @base_url)
    assert_nil book
  end

  def test_build_book_returns_nil_without_author
    no_author_html = <<~HTML
      <div class="flex pt-3 pb-3">
        <div>
          <a class="js-vim-focus" href="/book/123">Test Book</a>
          <span>2023</span>
        </div>
      </div>
    HTML
    
    doc = Nokogiri::HTML(no_author_html)
    raw_result = {
      text: doc.css('.flex.pt-3.pb-3').first.text.strip,
      element: doc.css('.flex.pt-3.pb-3').first
    }
    
    book = BookBuilder.build_book(raw_result, 0, @author_selector, @date_regex, @filetype_regex, @base_url)
    assert_nil book
  end

  def test_build_book_handles_missing_optional_fields
    minimal_html = <<~HTML
      <div class="flex pt-3 pb-3">
        <div>
          <a href="/search?q=author">Test Author</a>
          <a class="js-vim-focus" href="/book/123">Test Book</a>
        </div>
      </div>
    HTML
    
    doc = Nokogiri::HTML(minimal_html)
    raw_result = {
      text: doc.css('.flex.pt-3.pb-3').first.text.strip,
      element: doc.css('.flex.pt-3.pb-3').first
    }
    
    book = BookBuilder.build_book(raw_result, 0, @author_selector, @date_regex, @filetype_regex, @base_url)
    
    refute_nil book
    assert_nil book[:date]
    assert_nil book[:filetype]
    assert_equal "https://annas-archive.org/book/123", book[:url]
  end

  def test_build_books_filters_nil_results
    html_with_ad = <<~HTML
      <div class="flex pt-3 pb-3">
        <div>
          <a href="/search?q=author">Valid Author</a>
          <a class="js-vim-focus" href="/book/123">Valid Book</a>
        </div>
      </div>
      <div class="flex pt-3 pb-3">
        <div>
          Your ad here.
        </div>
      </div>
    HTML
    
    doc = Nokogiri::HTML(html_with_ad)
    raw_results = doc.css('.flex.pt-3.pb-3').map do |result|
      {
        text: result.text.strip,
        element: result
      }
    end
    
    books = BookBuilder.build_books(raw_results, @author_selector, @date_regex, @filetype_regex, @base_url)
    
    assert_equal 1, books.length
    refute_nil books.first[:author]
  end
end