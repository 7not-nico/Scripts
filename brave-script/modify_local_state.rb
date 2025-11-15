home = ENV['HOME']
path = File.join(home, '.config/BraveSoftware/Brave-Browser/Local State')
content = File.read(path)

pattern = /:{"enabled":false,"enabled_time":"[^"]*"}/
insertion = ',"browser":{"enabled_labs_experiments":["default-angle-vulkan@1","enable-gpu-rasterization@1","enable-zero-copy@1","ignore-gpu-blocklist","pdf-use-skia-renderer@1","skia-graphite@1","vulkan-from-angle@1"]}'

content.gsub!(pattern) { |match| match + insertion }

File.write(path, content)
