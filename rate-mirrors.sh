#!/bin/bash

# CachyOS Rate Mirrors Script
# Usage: ./rate-mirrors.sh

set -e

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

check_repos() {
    local cache_file="/tmp/repos_cache"
    
    if [ -f "$cache_file" ] && [ $(find "$cache_file" -mtime -1 2>/dev/null) ]; then
        print_status "Using cached repo list"
        cat "$cache_file"
        return
    fi
    
    print_status "Caching available repos..."
    grep "^\[" /etc/pacman.conf | sed 's/\[//;s/\]//' > "$cache_file"
    cat "$cache_file"
}

check_rate_mirrors_run() {
    local marker_file="/tmp/cachyos_rate_mirrors_run"
    
    if [ -f "$marker_file" ] && [ $(find "$marker_file" -mtime -7 2>/dev/null) ]; then
        print_status "cachyos-rate-mirrors already run recently (within 7 days)"
        return 0
    fi
    
    return 1
}

main() {
    check_repos
    
    if check_rate_mirrors_run; then
        print_status "Skipping mirror rating - already done recently"
    else
        print_status "Installing cachyos-rate-mirrors..."
        sudo pacman -S --needed --noconfirm cachyos-rate-mirrors
        
        print_status "Running cachyos-rate-mirrors..."
        sudo cachyos-rate-mirrors
        
        touch "/tmp/cachyos_rate_mirrors_run"
        print_status "Mirror rating complete!"
    fi
    
    print_status "Installing fish shell and octopi with paru..."
    paru -S --needed --noconfirm fish octopi
}

main "$@"