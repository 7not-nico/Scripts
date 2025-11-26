#!/bin/bash

# CachyOS Rate Mirrors Script
# Usage: ./rate-mirrors.sh

set -e

print_status() {
    echo "󰍉 $1"
}

ask_user_rate_mirrors() {
    while true; do
        read -p " Run cachyos-rate-mirrors to optimize package download speeds? (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

ask_user_hardware_detection() {
    while true; do
        read -p " Run hardware detection with chwd to configure drivers? (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

main() {
    print_status "Installing paru first..."
    sudo pacman -S --needed --noconfirm paru-bin
    
    print_status "Installing cachyos-hello and cachyos-kernel-manager first..."
    paru -S --needed --noconfirm cachyos-hello cachyos-kernel-manager
    
    if ask_user_rate_mirrors; then
        print_status "Installing cachyos-rate-mirrors..."
        sudo pacman -S --needed --noconfirm cachyos-rate-mirrors
        
        print_status "Running cachyos-rate-mirrors..."
        sudo cachyos-rate-mirrors
        
        print_status " Mirror rating complete!"
    else
        print_status "Skipping mirror rating"
    fi
    
    if ask_user_hardware_detection; then
        print_status "Installing chwd..."
        paru -S --needed --noconfirm chwd
        
        print_status "Running hardware detection with chwd..."
        sudo chwd -a || true
        
        print_status " Hardware detection complete!"
    else
        print_status "Skipping hardware detection"
    fi
    
    print_status "Installing system utilities, browsers, editors, and development tools with paru..."
    paru -S --needed --noconfirm \
        fish 7zip octopi dropbox \
        brave-bin zen-browser-bin \
        opencode gemini-cli lapce zed \
        yazi \
        python go zig ocaml ruby nodejs rust love \
        bun-bin uv
    
    print_status "Launching cachyos-hello..."
    cachyos-hello
}

main "$@"
