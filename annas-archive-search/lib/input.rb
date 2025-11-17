class Input
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