#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'
require 'tempfile'
require 'colorize'

require_relative '../lib/display'
require_relative '../lib/input'
require_relative '../lib/network'

class TestDisplay < Minitest::Test
  def test_truncate_short_string
    result = Display.truncate("short", 10)
    assert_equal "short", result
  end

  def test_truncate_long_string
    result = Display.truncate("this is a very long string", 9)
    assert_equal "this is a...", result
  end

  def test_truncate_exact_length
    result = Display.truncate("exact", 5)
    assert_equal "exact", result
  end

  def test_filetype_color_known_formats
    assert_equal "PDF".green, Display.filetype_color("PDF")
    assert_equal "EPUB".blue, Display.filetype_color("EPUB")
    assert_equal "MOBI".yellow, Display.filetype_color("MOBI")
    assert_equal "LIT".magenta, Display.filetype_color("LIT")
    assert_equal "CHM".cyan, Display.filetype_color("CHM")
    assert_equal "DJVU".red, Display.filetype_color("DJVU")
    assert_equal "ZIP".light_blue, Display.filetype_color("ZIP")
  end

  def test_filetype_color_unknown_format
    assert_equal "UNKNOWN".white, Display.filetype_color("UNKNOWN")
  end
end

class TestInput < Minitest::Test
  def test_validate_search_query_valid
    assert Input.validate_search_query("ruby programming")
    assert Input.validate_search_query("test query with spaces")
    assert Input.validate_search_query("book-title_with.symbols")
  end

  def test_validate_search_query_empty
    refute Input.validate_search_query("")
    refute Input.validate_search_query("   ")
    refute Input.validate_search_query(nil)
  end

  def test_validate_search_query_too_long
    long_query = "a" * 201
    refute Input.validate_search_query(long_query)
  end

  def test_validate_search_query_dangerous_chars
    refute Input.validate_search_query("query<script>")
    refute Input.validate_search_query("query</script>")
    refute Input.validate_search_query("query; rm -rf")
    refute Input.validate_search_query("query| cat /etc/passwd")
    refute Input.validate_search_query("query`whoami`")
    refute Input.validate_search_query("query$(command)")
    refute Input.validate_search_query("query{test}")
    refute Input.validate_search_query("query[test]")
  end

  def test_validate_search_query_control_chars
    refute Input.validate_search_query("query\x00null")
    refute Input.validate_search_query("query\x1F")
  end

  def test_parse_selection_all
    result = Input.parse_selection("all", 5)
    assert_equal [0, 1, 2, 3, 4], result
  end

  def test_parse_selection_all_case_insensitive
    result = Input.parse_selection("ALL", 5)
    assert_equal [0, 1, 2, 3, 4], result
  end

  def test_parse_selection_single_number
    result = Input.parse_selection("2", 5)
    assert_equal [1], result
  end

  def test_parse_selection_multiple_numbers
    result = Input.parse_selection("1,3,5", 5)
    assert_equal [0, 2, 4], result
  end

  def test_parse_selection_with_spaces
    result = Input.parse_selection(" 1 , 3 , 5 ", 5)
    assert_equal [0, 2, 4], result
  end

  def test_parse_selection_filters_out_of_range
    result = Input.parse_selection("1,10", 5)
    assert_equal [0], result
  end

  def test_parse_selection_filters_negative
    result = Input.parse_selection("-1,1", 5)
    assert_equal [0], result
  end

  def test_parse_selection_empty_result
    result = Input.parse_selection("10,15", 5)
    assert_equal [], result
  end

  def test_parse_selection_by_position_basic
    books = (1..5).map { |i| { index: i, title: "Book #{i}" } }
    result = Input.parse_selection_by_position("3", books)
    assert_equal [2], result
  end

  def test_parse_selection_by_position_multiple
    books = (1..5).map { |i| { index: i, title: "Book #{i}" } }
    result = Input.parse_selection_by_position("1,3,5", books)
    assert_equal [0, 2, 4], result
  end

  def test_parse_selection_by_position_all
    books = (1..5).map { |i| { index: i, title: "Book #{i}" } }
    result = Input.parse_selection_by_position("all", books)
    assert_equal [0, 1, 2, 3, 4], result
  end

  def test_parse_selection_by_position_out_of_range
    books = (1..3).map { |i| { index: i, title: "Book #{i}" } }
    result = Input.parse_selection_by_position("1,5,10", books)
    assert_equal [0], result
  end
end

class TestNetwork < Minitest::Test
  def test_build_search_url_encodes_query
    url = Network.build_search_url("test query", "https://example.com")
    assert_equal "https://example.com/search?q=test+query", url
  end

  def test_build_search_url_handles_special_characters
    url = Network.build_search_url("test & query", "https://example.com")
    assert_equal "https://example.com/search?q=test+%26+query", url
  end

  def test_build_search_url_handles_spaces
    url = Network.build_search_url("multiple   spaces", "https://example.com")
    assert_equal "https://example.com/search?q=multiple+++spaces", url
  end
end