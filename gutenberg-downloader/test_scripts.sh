#!/bin/bash

# Scripts to test
scripts=(
    "python download_books.py"
    "node download_books.js"
    "ruby download_books.rb"
    "cargo run --bin download_books"
    "zig run download_books.zig"
    "java DownloadBooks"
    "npx tsx download_books.ts"
)

# Number of runs per script
runs=1

# Output file
output_file="newtimings.md"

export TIMEFORMAT="%R"

# Function to get average time for a script
get_avg_time() {
    local script="$1"
    local sum=0
    local count=0
    for ((i=1; i<=runs; i++)); do
        rm -f book_*.txt
        time_output=$( { time $script; } 2>&1 )
        time_val=$(echo "$time_output" | tail -1)
        if [[ $time_val =~ ^[0-9]*\.?[0-9]+$ ]]; then
            sum=$(echo "$sum + $time_val" | bc -l 2>/dev/null)
            count=$((count + 1))
        fi
    done
    if (( count > 0 )); then
        avg=$(echo "scale=3; $sum / $count" | bc -l 2>/dev/null)
        printf "0m%.3fs" $avg
    else
        echo "0m0.000s"
    fi
}

# Map to display names
declare -A display_names
display_names["python download_books.py"]="Python"
display_names["node download_books.js"]="JavaScript"
display_names["ruby download_books.rb"]="Ruby"
display_names["cargo run --bin download_books"]="Rust"
display_names["zig run download_books.zig"]="Zig"
display_names["java DownloadBooks"]="Java"
display_names["npx tsx download_books.ts"]="TypeScript"

# Write to md file
cat > "$output_file" << EOF
| Script | Time |
|--------|------|
EOF

for script in "${scripts[@]}"; do
    avg_time=$(get_avg_time "$script")
    display=${display_names["$script"]}
    echo "| $display | $avg_time |" >> "$output_file"
done

echo "Results written to $output_file"