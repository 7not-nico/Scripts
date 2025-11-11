#!/bin/bash

# CachyOS Rate Mirrors Script
# Usage: ./install_rate_mirrors.sh

set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

install_package() {
    local package="$1"
    
    # Try *v4
    for repo in $(grep "^\[.*v4\]" /etc/pacman.conf | sed 's/\[//;s/\]//'); do
        pacman -S --needed --noconfirm "$repo/$package" 2>/dev/null && return 0
    done
    
    # Try *v3  
    for repo in $(grep "^\[.*v3\]" /etc/pacman.conf | sed 's/\[//;s/\]//'); do
        pacman -S --needed --noconfirm "$repo/$package" 2>/dev/null && return 0
    done
    
    # Try cachyos*
    for repo in $(grep "^\[cachyos" /etc/pacman.conf | sed 's/\[//;s/\]//'); do
        pacman -S --needed --noconfirm "$repo/$package" 2>/dev/null && return 0
    done
    
    # Ask user
    echo "Package '$package' not found. Available repos:"
    grep "^\[" /etc/pacman.conf | sed 's/\[//;s/\]//' | nl
    read -p "Choose repo number (0 to skip): " choice
    [ "$choice" != "0" ] && pacman -S --needed --noconfirm "$(grep "^\[" /etc/pacman.conf | sed 's/\[//;s/\]//' | sed -n "${choice}p")/$package"
}

install_packages() {
    for package in paru-bin yazi lapce zed octopi; do
        install_package "$package"
    done
}

# Main function
main() {
    print_status "Installing cachyos-rate-mirrors..."
    sudo pacman -S --needed --noconfirm cachyos-rate-mirrors
    
    print_status "Running cachyos-rate-mirrors..."
    sudo cachyos-rate-mirrors
    
    print_status "Mirror rating complete!"
    
    install_packages
    
    print_status "All installations complete!"
}

main "$@"