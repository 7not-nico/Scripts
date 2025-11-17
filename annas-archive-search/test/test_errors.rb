#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'
require 'net/http'
require 'socket'
require 'json'
require 'open-uri'

require_relative '../lib/errors'

class TestErrors < Minitest::Test
  def test_handle_http_errors
    # Test 4xx errors
    error_404 = OpenURI::HTTPError.new("404 Not Found", nil)
    assert_raises(SystemExit) { Errors.handle_network(error_404) }
    
    # Test 5xx errors
    error_500 = OpenURI::HTTPError.new("500 Internal Server Error", nil)
    assert_raises(SystemExit) { Errors.handle_network(error_500) }
    
    error_503 = OpenURI::HTTPError.new("503 Service Unavailable", nil)
    assert_raises(SystemExit) { Errors.handle_network(error_503) }
  end

  def test_handle_network_errors
    # Test socket errors
    socket_error = SocketError.new("getaddrinfo: Name or service not known")
    assert_raises(SystemExit) { Errors.handle_network(socket_error) }
    
    # Test timeout errors
    timeout_error = Net::ReadTimeout.new
    assert_raises(SystemExit) { Errors.handle_network(timeout_error) }
    
    # Test connection errors
    conn_error = Errno::ECONNREFUSED.new("Connection refused")
    assert_raises(SystemExit) { Errors.handle_network(conn_error) }
  end

  def test_handle_cache_errors
    # Test JSON parser error
    json_error = JSON::ParserError.new("unexpected token")
    result = Errors.handle_cache(json_error, "load")
    assert_equal true, result # Should clear cache
    
    # Test permission error
    perm_error = Errno::EACCES.new("Permission denied")
    result = Errors.handle_cache(perm_error, "save")
    assert_equal false, result
    
    # Test file not found
    not_found = Errno::ENOENT.new("No such file")
    result = Errors.handle_cache(not_found, "load")
    assert_equal false, result
  end

  def test_handle_basic_error
    assert_raises(SystemExit) { Errors.handle("Test error") }
    assert_raises(SystemExit) { Errors.handle("Test error", 2) }
  end
end