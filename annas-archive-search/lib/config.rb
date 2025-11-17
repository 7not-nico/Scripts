require_relative 'errors'

# Configuration
module Config
  CACHE = {
    dir: File.expand_path('~/.cache/annas_search'),
    ttl: 3600,  # 1 hour
    cleanup_probability: 0.1  # 10% chance to cleanup on each run
  }

  DISPLAY = {
    title_max_len: 50,
    author_max_len: 30
  }

  NETWORK = {
    open_timeout: 10,
    read_timeout: 30,
    base_url: 'https://annas-archive.org'
  }

  BROWSERS = {
    fallbacks: ['brave --app', 'firefox --new-window', 'chromium --app'],
    cmd: ENV['BROWSER_COMMAND']
  }

  DEBUG = ENV['DEBUG'] == '1'

  PARSING = {
    result_selector: '.flex.pt-3.pb-3',
    author_selector: 'a[href*="/search?q="]',
    date_regex: /\b(19[0-9]{2}|20[0-2][0-9])\b/,
    filetype_regex: / · ([A-Z]{3,4}) · /
  }

  def self.validate
    begin
      FileUtils.mkdir_p(CACHE[:dir])
    rescue => e
      Errors.handle("Failed to create cache directory #{CACHE[:dir]}: #{e.message}")
    end

    # Validate timeouts are reasonable
    Errors.handle("Invalid timeout values") if NETWORK[:open_timeout] <= 0 || NETWORK[:read_timeout] <= 0

    # Validate cache settings
    Errors.handle("Invalid cache TTL") if CACHE[:ttl] <= 0
    Errors.handle("Invalid cleanup probability") unless (0..1).include?(CACHE[:cleanup_probability])

    # Validate display lengths
    Errors.handle("Invalid display lengths") if DISPLAY[:title_max_len] <= 0 || DISPLAY[:author_max_len] <= 0
  end
end