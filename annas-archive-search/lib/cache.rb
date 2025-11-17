class Cache
  def self.get_file(search, cache_dir)
    "#{cache_dir}/#{Digest::SHA256.hexdigest(search)}.json"
  end

  def self.load(cache_file, ttl)
    return nil unless File.exist?(cache_file) && (Time.now - File.mtime(cache_file)) < ttl

    begin
      JSON.parse(File.read(cache_file), symbolize_names: true)
    rescue JSON::ParserError
      nil
    end
  end

  def self.save(cache_file, books)
    File.write(cache_file, JSON.generate(books)) unless books.empty?
  end

  def self.cleanup(cache_dir, ttl, probability)
    return unless rand < probability
    now = Time.now
    Dir.each_child(cache_dir) do |file|
      next unless file.end_with?('.json')
      filepath = File.join(cache_dir, file)
      File.delete(filepath) if (now - File.mtime(filepath)) >= ttl
    end
  end
end