#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'
require 'net/http'
require 'socket'

require_relative '../lib/network'

class TestNetworkRetry < Minitest::Test
  def setup
    @url = 'http://httpbin.org/status/500'
    @success_url = 'http://httpbin.org/get'
    @timeout = 5
  end

  def test_fetch_with_retry_succeeds_on_first_try
    # This test assumes httpbin.org is available
    skip "Network test - requires internet connection"
    
    result = Network.fetch_with_retry(@success_url, 5, 5, 1)
    refute_nil result
  end

  def test_build_search_url_encoding
    url = Network.build_search_url("test & query", "https://example.com")
    assert_equal "https://example.com/search?q=test+%26+query", url
  end

  def test_build_search_url_special_chars
    url = Network.build_search_url("test+query", "https://example.com")
    assert_equal "https://example.com/search?q=test%2Bquery", url
  end
end