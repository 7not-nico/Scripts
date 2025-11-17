class Errors
  def self.handle(message, exit_code = 1)
    puts "Error: #{message}"
    exit exit_code
  end

  def self.handle_network(error)
    case error
    when OpenURI::HTTPError
      handle("HTTP #{error.message} - site may be down or blocking requests")
    when SocketError
      handle("Network connection failed - check your internet connection and try again")
    else
      handle("Failed to fetch results - #{error.message} (try again later)")
    end
  end
end