require_relative 'errors'

# Configuration
class Config
  class << self
    def cache
      {
        dir: File.expand_path('~/.cache/annas_search'),
        ttl: 3600,  # 1 hour
        cleanup_probability: 0.1  # 10% chance to cleanup on each run
      }
    end

    def display
      {
        title_max_len: 50,
        author_max_len: 30
      }
    end

    def network
      {
        open_timeout: 10,
        read_timeout: 30,
        base_url: 'https://annas-archive.org'
      }
    end

    def browsers
      {
        fallbacks: ['brave --app', 'firefox --new-window', 'chromium --app'],
        cmd: ENV['BROWSER_COMMAND']
      }
    end

    def debug
      ENV['DEBUG'] == '1'
    end

    def parsing
      {
        result_selector: '.flex.pt-3.pb-3',
        author_selector: 'a[href*="/search?q="]',
        date_regex: /\b(19[0-9]{2}|20[0-2][0-9])\b/,
        filetype_regex: / · ([A-Z]{3,4}) · /
      }
    end

    def validate
      begin
        FileUtils.mkdir_p(cache[:dir])
      rescue => e
        Errors.handle("Failed to create cache directory #{cache[:dir]}: #{e.message}")
      end

      # Validate timeouts are reasonable
      Errors.handle("Invalid timeout values") if network[:open_timeout] <= 0 || network[:read_timeout] <= 0

      # Validate cache settings
      Errors.handle("Invalid cache TTL") if cache[:ttl] <= 0
      Errors.handle("Invalid cleanup probability") unless (0..1).include?(cache[:cleanup_probability])

      # Validate display lengths
      Errors.handle("Invalid display lengths") if display[:title_max_len] <= 0 || display[:author_max_len] <= 0
    end
  end
end