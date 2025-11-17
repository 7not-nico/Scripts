require 'nokogiri'
require 'open-uri'

class Network
  def self.build_search_url(query, base_url)
    "#{base_url}/search?q=#{URI.encode_www_form_component(query)}"
  end

  def self.fetch(url, open_timeout, read_timeout)
    URI.open(url, open_timeout: open_timeout, read_timeout: read_timeout)
  end

  def self.fetch_html(url, open_timeout, read_timeout)
    Nokogiri::HTML(fetch(url, open_timeout, read_timeout))
  end
end