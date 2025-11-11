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

check_updates_complete() {
    ! pacman -Qu | grep -q .
}

# Main installation
main() {
    print_status "Starting CachyOS installation..."
    
    # Update system first
    print_status "Updating system..."
    sudo pacman -Syu --noconfirm
    
    # Check if updates are still pending and restart if needed
    if ! check_updates_complete; then
        print_status "Updates still pending. Rebooting to complete updates..."
        sudo reboot
        exit 0
    fi
    
    print_status "System is up to date. Continuing installation..."
    
    # Install paru-bin for AUR
    if ! command -v paru &> /dev/null; then
        print_status "Installing paru-bin..."
        # Try to install from repos first
        if sudo pacman -S --needed --noconfirm paru-bin 2>/dev/null; then
            print_status "paru-bin installed from repos"
        else
            # Fallback: install from AUR using makepkg
            print_status "Installing paru-bin from AUR..."
            sudo pacman -S --needed --noconfirm base-devel git
            git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
            cd /tmp/paru-bin
            makepkg -si --noconfirm
            cd - && rm -rf /tmp/paru-bin
        fi
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
        paru-bin \
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
        shortwave \
        dropbox
    
    # Setup hardware
    print_status "Detecting hardware..."
    sudo chwd -a auto
    
    # Clean up
    print_status "Cleaning up..."
    paru -c --noconfirm
    
    print_status "Installation complete!"
}

main "$@"