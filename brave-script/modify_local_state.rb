require 'json'

home = ENV['HOME']
path = File.join(home, '.config/BraveSoftware/Brave-Browser/Local State')
content = File.read(path)
data = JSON.parse(content)
data['brave'] ||= {}
data['brave']['enabled_labs_experiments'] = ["default-angle-vulkan@1","enable-force-dark@6","enable-gpu-rasterization@1","enable-parallel-downloading@1","enable-zero-copy@1","ignore-gpu-blocklist","pdf-use-skia-renderer@1","skia-graphite@1","vulkan-from-angle@1"]
File.write(path, JSON.pretty_generate(data))
