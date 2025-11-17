#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'
require 'json'
require 'fileutils'
require 'tempfile'

require_relative '../lib/cache'
require_relative '../lib/parser'
require_relative '../lib/book_builder'

class TestCache < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @cache_file = File.join(@temp_dir, "test.json")
    @test_books = [
      { title: "Test Book", author: "Test Author", url: "http://example.com" }
    ]
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_get_file_creates_hash_path
    file = Cache.get_file("test query", @temp_dir)
    assert file.start_with?(@temp_dir)
    assert file.end_with?(".json")
    refute_equal File.join(@temp_dir, "test.json"), file
  end

  def test_save_and_load_valid_cache
    Cache.save(@cache_file, @test_books)
    assert File.exist?(@cache_file)
    
    loaded = Cache.load(@cache_file, 3600)
    assert_equal @test_books, loaded
  end

  def test_load_returns_nil_for_nonexistent_file
    loaded = Cache.load(@cache_file, 3600)
    assert_nil loaded
  end

  def test_load_returns_nil_for_expired_cache
    Cache.save(@cache_file, @test_books)
    
    # Simulate expired cache
    File.utime(Time.now - 7200, Time.now - 7200, @cache_file)
    
    loaded = Cache.load(@cache_file, 3600)
    assert_nil loaded
  end

  def test_load_returns_nil_for_invalid_json
    File.write(@cache_file, "invalid json")
    
    loaded = Cache.load(@cache_file, 3600)
    assert_nil loaded
  end

  def test_save_skips_empty_books
    Cache.save(@cache_file, [])
    refute File.exist?(@cache_file)
  end

  def test_cleanup_removes_expired_files
    # Create expired and fresh files
    expired_file = File.join(@temp_dir, "expired.json")
    fresh_file = File.join(@temp_dir, "fresh.json")
    
    File.write(expired_file, "{}")
    File.write(fresh_file, "{}")
    
    File.utime(Time.now - 7200, Time.now - 7200, expired_file)
    
    Cache.cleanup(@temp_dir, 3600, 1.0) # 100% probability
    
    refute File.exist?(expired_file)
    assert File.exist?(fresh_file)
  end

  def test_enforce_size_limits_file_count
    # Create more files than the limit
    (1005).times do |i|
      File.write(File.join(@temp_dir, "file_#{i}.json"), "{}")
    end
    
    Cache.enforce_size_limits(@temp_dir)
    
    remaining_files = Dir.glob(File.join(@temp_dir, '*.json'))
    assert_equal 1000, remaining_files.size
  end

  def test_enforce_size_limits_file_size
    # Create files that exceed size limit
    large_content = "x" * 1024 * 1024  # 1MB per file
    (60).times do |i|
      File.write(File.join(@temp_dir, "large_#{i}.json"), large_content)
    end
    
    Cache.enforce_size_limits(@temp_dir)
    
    remaining_files = Dir.glob(File.join(@temp_dir, '*.json'))
    total_size = remaining_files.sum { |f| File.size(f) }
    assert total_size <= 50 * 1024 * 1024  # 50MB limit
  end

  def test_get_stats
    # Create some test files with larger content
    File.write(File.join(@temp_dir, "test1.json"), '{"data": "' + "x" * 5000 + '"}')
    File.write(File.join(@temp_dir, "test2.json"), '{"data": "' + "x" * 3000 + '"}')
    
    stats = Cache.get_stats(@temp_dir)
    
    assert_equal 2, stats[:files]
    assert stats[:size_mb] > 0
  end

  def test_get_stats_empty_dir
    stats = Cache.get_stats(@temp_dir)
    assert_equal 0, stats[:files]
    assert_equal 0, stats[:size_mb]
  end

  def test_enforce_size_limits_file_count_small
    # Create a few files under the limit
    (5).times do |i|
      File.write(File.join(@temp_dir, "file_#{i}.json"), "{}")
    end
    
    Cache.enforce_size_limits(@temp_dir, 10, 50) # 10 file limit
    
    remaining_files = Dir.glob(File.join(@temp_dir, '*.json'))
    assert_equal 5, remaining_files.size
  end
end