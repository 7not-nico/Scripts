class Input
  def self.validate_search_query(query)
    return false if query.nil? || query.strip.empty?
    
    # Check for potentially dangerous characters
    dangerous_patterns = [
      /[<>]/,           # HTML tags
      /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/,  # Control characters
      /[;&|`$(){}\[\]]/, # Shell injection characters
    ]
    
    dangerous_patterns.each do |pattern|
      return false if query.match?(pattern)
    end
    
    # Length validation
    return false if query.length > 200
    
    true
  end

  def self.parse_selection(input, count)
    return (0...count).to_a if input.downcase == 'all'
    input.split(',').map { |n| n.strip.to_i - 1 }.select { |n| n.between?(0, count - 1) }
  end

  def self.get(selection)
    return selection if selection
    puts "Enter numbers (comma-separated or 'all'):"
    STDIN.gets&.chomp&.strip || ''
  end
end