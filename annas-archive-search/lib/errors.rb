class Errors
  def self.handle(message, exit_code = 1)
    puts "Error: #{message}"
    exit exit_code
  end

  def self.handle_network(error)
    case error
    when OpenURI::HTTPError
      case error.message
      when /^4\d\d/
        handle("HTTP #{error.message} - client error, check your request")
      when /^500/
        handle("HTTP #{error.message} - server error, try again later")
      when /^502/
        handle("HTTP #{error.message} - server gateway error, service temporarily unavailable")
      when /^503/
        handle("HTTP #{error.message} - service unavailable, server overloaded")
      when /^504/
        handle("HTTP #{error.message} - gateway timeout, try again later")
      else
        handle("HTTP #{error.message} - site may be down or blocking requests")
      end
    when SocketError
      handle("Network connection failed - check your internet connection and DNS settings")
    when Net::ReadTimeout
      handle("Request timeout - server took too long to respond, try again")
    when Net::OpenTimeout
      handle("Connection timeout - couldn't connect to server, check network")
    when Errno::ECONNREFUSED
      handle("Connection refused - server is not accepting connections")
    when Errno::EHOSTUNREACH
      handle("Host unreachable - server cannot be reached")
    when Errno::ENETUNREACH
      handle("Network unreachable - check your internet connection")
    when OpenSSL::SSL::SSLError
      handle("SSL error - secure connection failed")
    else
      handle("Failed to fetch results - #{error.message} (try again later)")
    end
  end

  def self.handle_cache(error, operation)
    case error
    when Errno::ENOENT
      # Cache file doesn't exist, this is normal
      return false
    when Errno::EACCES
      puts "Warning: Cache permission denied during #{operation}"
      return false
    when JSON::ParserError
      puts "Warning: Cache corrupted during #{operation}, clearing cache"
      return true # Signal to clear cache
    else
      puts "Warning: Cache error during #{operation}: #{error.message}"
      return false
    end
  end
end