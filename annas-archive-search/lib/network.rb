require 'nokogiri'
require 'open-uri'

class Network
  def self.build_search_url(query, base_url)
    "#{base_url}/search?q=#{URI.encode_www_form_component(query)}"
  end

  def self.fetch_with_retry(url, open_timeout, read_timeout, max_retries = 3)
    retries = 0
    
    begin
      fetch(url, open_timeout, read_timeout)
    rescue OpenURI::HTTPError => e
      if retries < max_retries && (e.message.start_with?('5') || e.message == '429')
        retries += 1
        delay = 2 ** retries
        sleep(delay)
        retry
      else
        raise
      end
    rescue SocketError, Net::ReadTimeout, Net::OpenTimeout => e
      if retries < max_retries
        retries += 1
        delay = 2 ** retries
        sleep(delay)
        retry
      else
        raise
      end
    end
  end

  def self.fetch(url, open_timeout, read_timeout)
    URI.open(url, open_timeout: open_timeout, read_timeout: read_timeout)
  end

  def self.fetch_html(url, open_timeout, read_timeout)
    Nokogiri::HTML(fetch_with_retry(url, open_timeout, read_timeout))
  end
end