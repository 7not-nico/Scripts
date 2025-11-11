#!/bin/bash

# Simple CachyOS Installation Script
# Usage: ./install_cachyos.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Main installation
main() {
    print_status "Starting CachyOS installation..."
    
    # Update system
    print_status "Updating system..."
    sudo pacman -Syu --noconfirm
    
    # Install paru for AUR
    if ! command -v paru &> /dev/null; then
        print_status "Installing paru..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si --noconfirm
        cd - && rm -rf /tmp/paru
    fi
    
    # Install CachyOS repos
    print_status "Installing CachyOS repositories..."
    if [ -f "cachyos-repo/cachyos-repo.sh" ]; then
        chmod +x cachyos-repo/cachyos-repo.sh
        sudo ./cachyos-repo/cachyos-repo.sh
    else
        print_status "Installing cachyos-repo package..."
        sudo pacman -S --needed --noconfirm cachyos-repo
    fi
    
    # Install packages
    print_status "Installing packages..."
    sudo pacman -S --needed --noconfirm \
        cachyos-configs \
        cachyos-hooks \
        cachyos-mirrorlist \
        cachyos-keyring \
        paru \
        chwd \
        htop \
        neofetch \
        git \
        curl \
        wget
    
    # Install AUR packages
    print_status "Installing AUR packages..."
    paru -S --needed --noconfirm \
        zen-browser-bin \
        shortwave
    
    # Setup hardware
    print_status "Detecting hardware..."
    sudo chwd -a auto
    
    # Clean up
    print_status "Cleaning up..."
    paru -c --noconfirm
    
    print_status "Installation complete! Please reboot your system."
}

main "$@"