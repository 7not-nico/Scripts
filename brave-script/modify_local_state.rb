home = ENV['HOME']   # Variable assignment, ENV hash access for environment variable

path = File.join(home, '.config/BraveSoftware/Brave-Browser/Local State')  # Method call on File class, string interpolation

content = File.read(path)  # Class method call to read file

pattern = /"first_run_finished"/  # Regular expression literal with / delimiters

insertion = '"browser":{"enabled_labs_experiments":["default-angle-vulkan@1","enable-gpu-rasterization@1","enable-zero-copy@1","ignore-gpu-blocklist","pdf-use-skia-renderer@1","skia-graphite@1","vulkan-from-angle@1"]},'  # String literal with array syntax

content.gsub!(pattern) { |match| insertion + match }  # Method call with block, |match| block parameter, string concatenation

File.write(path, content)  # Class method call to write file
