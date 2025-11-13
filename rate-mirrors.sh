#!/bin/bash

# CachyOS Rate Mirrors Script
# Usage: ./rate-mirrors.sh

set -e

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
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
    
    print_status "Installing fish, octopi, dropbox, brave-bin, zen-browser-bin, opencode-bin, gemini-cli, lapce, zed, cachyos-hello and chwd with paru..."
    paru -S --needed --noconfirm fish octopi dropbox brave-bin zen-browser-bin opencode-bin gemini-cli lapce zed cachyos-hello chwd libappindicator \
        python go zig ocaml ruby nodejs rust dotnet-sdk-bin 
    
    print_status "Running hardware detection with chwd..."
    sudo chwd -a || true
    
    print_status "Launching cachyos-hello..."
    cachyos-hello
}

main "$@"
