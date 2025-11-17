class Parser
  def self.extract_raw_results(doc, result_selector)
    doc.css(result_selector).map do |result|
      {
        text: result.text.strip,
        element: result
      }
    end
  end
end