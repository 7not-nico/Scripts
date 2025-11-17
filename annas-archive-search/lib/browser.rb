require_relative 'display'

class Browser
  @@available_browsers = []

  def self.open(book, fallbacks, debug, title_max)
    return unless book[:url]
    fallbacks.each do |browser|
      next unless available?(browser, debug)
      # Parse browser command into array and append URL
      cmd_parts = browser.split + [book[:url]]
      puts "DEBUG: Trying browser command: #{cmd_parts.join(' ')}" if debug
      success = system(*cmd_parts)
      puts "DEBUG: Browser command success: #{success}" if debug
      if success
        puts "Opened: #{Display.truncate(book[:title], title_max)}"
        return
      end
    end
    puts "Failed to open browser for: #{Display.truncate(book[:title], title_max)}"
  end

  def self.available?(browser_cmd, debug)
    return true if @@available_browsers.include?(browser_cmd)
    # Use 'which' to check if browser executable exists
    browser_exe = browser_cmd.split.first
    available = system("which #{browser_exe} >/dev/null 2>&1")
    puts "DEBUG: Browser '#{browser_cmd}' available: #{available}" if debug
    @@available_browsers << browser_cmd if available
    available
  end
end