#!/bin/bash

# CachyOS Rate Mirrors Script
# Usage: ./rate-mirrors.sh

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

install_aur_packages() {
    local packages="yazi lapce zed octopi"
    local aur_packages=""
    
    # Check which packages are not in repos
    for package in $packages; do
        local found=false
        
        # Check *v4 repos
        for repo in $(grep "^\[.*v4\]" /etc/pacman.conf | sed 's/\[//;s/\]//'); do
            pacman -Si "$repo/$package" >/dev/null 2>&1 && found=true && break
        done
        
        # Check *v3 repos
        if [ "$found" = false ]; then
            for repo in $(grep "^\[.*v3\]" /etc/pacman.conf | sed 's/\[//;s/\]//'); do
                pacman -Si "$repo/$package" >/dev/null 2>&1 && found=true && break
            done
        fi
        
        # Check cachyos* repos
        if [ "$found" = false ]; then
            for repo in $(grep "^\[cachyos" /etc/pacman.conf | sed 's/\[//;s/\]//'); do
                pacman -Si "$repo/$package" >/dev/null 2>&1 && found=true && break
            done
        fi
        
        # If not found in any repo, add to AUR list
        if [ "$found" = false ]; then
            aur_packages="$aur_packages $package"
        fi
    done
    
    # Install AUR packages only if any were found
    if [ -n "$aur_packages" ]; then
        print_status "Installing AUR packages:$aur_packages"
        paru -S --needed --noconfirm $aur_packages
    else
        print_status "All packages found in repos, no AUR installation needed"
    fi
}

# Main function
main() {
    print_status "Installing cachyos-rate-mirrors..."
    sudo pacman -S --needed --noconfirm cachyos-rate-mirrors
    
    print_status "Running cachyos-rate-mirrors..."
    sudo cachyos-rate-mirrors
    
    print_status "Mirror rating complete!"
    
    install_packages
    
    install_aur_packages
    
    print_status "All installations complete!"
}

main "$@"