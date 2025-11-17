import csv
from collections import defaultdict

def parse_time(t):
    if 'm' in t:
        m, s = t.split('m')
        s = s.rstrip('s')
        return int(m) * 60 + float(s)
    else:
        return float(t)

times = defaultdict(list)

with open('data.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        script = row['script']
        time_sec = parse_time(row['time'])
        times[script].append(time_sec)

# Map script names to display names
script_names = {
    'ruby download_books.rb': 'Ruby',
    'python download_books.py': 'Python',
    'zig run download_books.zig': 'Zig',
    'java DownloadBooks': 'Java',
    'node download_books.js': 'JavaScript',
    'cargo run --bin download_books': 'Rust',
    'cargo run': 'Rust',  # for old
    'npx tsx download_books.ts': 'TypeScript',
    'ts-node download_books.ts': 'TypeScript'  # for old
}

# Group by display name
display_times = defaultdict(list)
for script, time_list in times.items():
    display_name = script_names.get(script, script)
    display_times[display_name].extend(time_list)

print('| Script | Time |')
print('|--------|------|')
for display_name, time_list in display_times.items():
    avg_time = sum(time_list) / len(time_list)
    formatted_time = f'0m{avg_time:.3f}s'
    print(f'| {display_name} | {formatted_time} |')