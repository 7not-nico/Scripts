#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'

DIRS = %i[iwad pk3 wad].map { |t| [t, File.join(Dir.home, ".config", "gzdoom", t.to_s)] }.to_h
CONFIG_FILE = File.join(Dir.home, ".config", "gzdoom", "launcher")
C = {G: "\033[0;32m", Y: "\033[1;33m", B: "\033[0;34m", R: "\033[0;31m", N: "\033[0m"}

def select(files, prompt, multi: false, req: false)
  puts "\n#{C[:B]}=== #{prompt} ===#{C[:N]}"
  files.each_with_index { |f, i| puts "#{i+1}) #{f}" }
  puts "0) Done" if multi
  
  unless multi
    loop { 
      print "Choice (1-#{files.size}): "
      c = gets.chomp
      n = c.to_i
      return files[n-1] if n.between?(1, files.size)
      puts "#{C[:R]}[ERROR]#{C[:N]} Enter 1-#{files.size}"
    }
  end
  
  sel = []
  loop { 
    print "Choice (0 to finish): "
    c = gets.chomp
    break if c == "0" && (!req || !sel.empty?)
    next if c == "0"
    n = c.to_i
    next unless n.between?(1, files.size)
    f = files[n-1]
    if sel.include?(f)
      puts "#{C[:Y]}[WARN]#{C[:N]} Already selected: #{f}"
    else
      sel << f
      puts "#{C[:G]}[INFO]#{C[:N]} Selected: #{f}"
    end
  }
  sel
end

def select_or_skip(files, prompt, multi: false)
  files.empty? ? (puts "#{C[:Y]}[WARN]#{C[:N]} No #{prompt.split.last} files found - skipping"; []) : select(files, prompt, multi: multi)
end

exit unless system("which gzdoom > /dev/null 2>&1")
DIRS.each_value { |d| FileUtils.mkdir_p(d) }

iwads = Array("*.wad").flat_map { |pat| Dir.glob("#{DIRS[:iwad]}/*").map { |f| File.basename(f) }.select { |f| File.fnmatch(pat, f, File::FNM_CASEFOLD) } }.uniq.sort
pk3s = Array(["*.pk3", "*.zip", "*.7z"]).flat_map { |pat| Dir.glob("#{DIRS[:pk3]}/*").map { |f| File.basename(f) }.select { |f| File.fnmatch(pat, f, File::FNM_CASEFOLD) } }.uniq.sort
wads = Dir.glob("#{DIRS[:wad]}/*").map { |f| File.basename(f) }.reject { |f| File.fnmatch("*.zip", f, File::FNM_CASEFOLD) }.sort

puts "#{C[:R]}[ERROR]#{C[:N]} No IWAD files found" && exit(1) if iwads.empty?

puts "#{C[:G]}=== GZDoom Launcher ===#{C[:N]}"
puts "Found #{iwads.size} IWAD(s), #{pk3s.size} PK3(s), #{wads.size} WAD(s)"

config = File.exist?(CONFIG_FILE) ? File.read(CONFIG_FILE).strip : nil
config = nil if config && config.empty?

if config
  saved_config = YAML.load(config)
  iwad = saved_config[:iwad]
  sel_pk3s = saved_config[:pk3s] || []
  sel_wads = saved_config[:wads] || []
  
  puts "#{C[:G]}=== Saved Configuration Found ===#{C[:N]}"
  puts "IWAD: #{iwad}"
  puts "PK3s: #{sel_pk3s.join(', ')}" unless sel_pk3s.empty?
  puts "WADs: #{sel_wads.join(', ')}" unless sel_wads.empty?
  
  print "\nUse saved configuration? (Y/n/w for custom WAD/i for custom IWAD/p for custom PK3): "
  choice = gets.chomp.downcase
  if choice == "w"
    puts "#{C[:G]}[INFO]#{C[:N]} Using saved IWAD and PK3s, selecting new WADs"
    sel_wads = select_or_skip(wads, "Select WAD files", multi: true)
  elsif choice == "i"
    puts "#{C[:G]}[INFO]#{C[:N]} Using saved PK3s and WADs, selecting new IWAD"
    iwad = select(iwads, "Select IWAD")
  elsif choice == "p"
    puts "#{C[:G]}[INFO]#{C[:N]} Using saved IWAD and WADs, selecting new PK3s"
    sel_pk3s = select_or_skip(pk3s, "Select PK3 files", multi: true)
  elsif choice != "n"
    puts "#{C[:G]}[INFO]#{C[:N]} Using saved selections"
  else
    iwad = select(iwads, "Select IWAD")
    sel_pk3s = select_or_skip(pk3s, "Select PK3 files", multi: true)
    sel_wads = select_or_skip(wads, "Select WAD files", multi: true)
  end
else
  iwad = select(iwads, "Select IWAD")
  sel_pk3s = select_or_skip(pk3s, "Select PK3 files", multi: true)
  sel_wads = select_or_skip(wads, "Select WAD files", multi: true)
end

puts "\n#{C[:G]}=== Launch Configuration ===#{C[:N]}"
puts "IWAD: #{iwad}"
puts "PK3s: #{sel_pk3s.join(', ')}" unless sel_pk3s.empty?
puts "WADs: #{sel_wads.join(', ')}" unless sel_wads.empty?

print "\nLaunch? (Y/n): "
gets.chomp.downcase == "n" ? (puts "#{C[:G]}[INFO]#{C[:N]} Cancelled"; exit(0)) : nil

cmd = ["gzdoom", "-iwad", File.join(DIRS[:iwad], iwad)]
[sel_pk3s, sel_wads].each_with_index { |files, i| files.each { |f| cmd.concat(["-file", File.join(DIRS[i == 0 ? :pk3 : :wad], f)]) } }

config_data = { iwad: iwad, pk3s: sel_pk3s, wads: sel_wads }
File.write(CONFIG_FILE, config_data.to_yaml)

puts "#{C[:G]}[INFO]#{C[:N]} Launching: #{cmd.join(' ')}"
system({"GZDOOM_VERSION" => "4.11.0"}, *cmd)
exit($?.exitstatus || 0)