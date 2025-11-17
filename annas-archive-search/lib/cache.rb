require 'digest'

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
    return if books.empty?
    
    File.write(cache_file, JSON.generate(books))
    File.utime(Time.now, Time.now, cache_file) # Update access time for LRU
  end

  def self.cleanup(cache_dir, ttl, probability, max_files = 1000, max_size_mb = 50)
    return unless Dir.exist?(cache_dir) && rand < probability
    
    # Remove expired files first
    cleanup_expired(cache_dir, ttl)
    
    # Then enforce size limits
    enforce_size_limits(cache_dir, max_files, max_size_mb)
  end

  def self.cleanup_expired(cache_dir, ttl)
    now = Time.now
    Dir.each_child(cache_dir) do |file|
      next unless file.end_with?('.json')
      filepath = File.join(cache_dir, file)
      File.delete(filepath) if (now - File.mtime(filepath)) >= ttl
    end
  end

  def self.enforce_size_limits(cache_dir, max_files = 1000, max_size_mb = 50)
    cache_files = Dir.glob(File.join(cache_dir, '*.json'))
    return if cache_files.empty?
    
    # Check file count limit
    if cache_files.size > max_files
      files_by_access = cache_files.sort_by { |f| File.mtime(f) }
      files_to_remove = files_by_access.first(cache_files.size - max_files)
      files_to_remove.each { |f| File.delete(f) if File.exist?(f) }
      cache_files -= files_to_remove
    end
    
    # Check size limit
    max_size_bytes = max_size_mb * 1024 * 1024
    total_size = cache_files.sum { |f| File.exist?(f) ? File.size(f) : 0 }
    
    if total_size > max_size_bytes
      files_by_access = cache_files.sort_by { |f| File.mtime(f) }
      current_size = total_size
      
      files_by_access.each do |file|
        break if current_size <= max_size_bytes
        next unless File.exist?(file)
        
        file_size = File.size(file)
        File.delete(file)
        current_size -= file_size
      end
    end
  end

  def self.get_stats(cache_dir)
    return { files: 0, size_mb: 0 } unless Dir.exist?(cache_dir)
    
    cache_files = Dir.glob(File.join(cache_dir, '*.json'))
    return { files: 0, size_mb: 0 } if cache_files.empty?
    
    total_size = cache_files.sum { |f| File.exist?(f) ? File.size(f) : 0 }
    
    {
      files: cache_files.size,
      size_mb: (total_size.to_f / 1024 / 1024).round(2)
    }
  end
end