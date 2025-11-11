#!/bin/bash

# CachyOS Automated Installation Script
# Usage: ./install_cachyos.sh

set -e

# Check if CachyOS repos are already configured
if ! grep -q "cachyos\|cachyos-v3\|cachyos-v4\|cachyos-znver4" /etc/pacman.conf; then
    echo "CachyOS repos not found. Setting up repository..."
    # Download and extract the installer
    curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    
    # Run the automated installer
    sudo ./cachyos-repo.sh
    cd -
else
    echo "CachyOS repos already configured."
fi

# Check if cachyos-rate-mirrors is installed
if ! command -v cachyos-rate-mirrors &> /dev/null; then
    echo "cachyos-rate-mirrors not found. Installing paru and cachyos-rate-mirrors..."

    # Check if paru is already installed (either paru or paru-bin)
    if ! command -v paru &> /dev/null; then
        echo "Installing paru..."
        yay -S --noconfirm paru
    else
        echo "paru already installed."
    fi

    # Install and run mirror ranking tool
    echo "Installing cachyos-rate-mirrors..."
    paru -S --noconfirm cachyos-rate-mirrors
    echo "Running mirror ranking..."
    sudo cachyos-rate-mirrors --force
else
    echo "cachyos-rate-mirrors already installed."
    
    # Check if mirrors have been ranked before (check for recent mirrorlist updates)
    arch_mirrorlist="/etc/pacman.d/mirrorlist"
    cachyos_mirrorlist="/etc/pacman.d/cachyos-mirrorlist"
    
    mirrors_ranked=false
    if [[ -f "$arch_mirrorlist" ]] && grep -q "Server = https://.*archlinux" "$arch_mirrorlist"; then
        if [[ -f "$cachyos_mirrorlist" ]] && grep -q "Server = https://.*cachyos" "$cachyos_mirrorlist"; then
            mirrors_ranked=true
        fi
    fi
    
    if $mirrors_ranked; then
        echo "Mirror ranking has been run before."
        read -p "Do you want to run mirror ranking again? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Running mirror ranking..."
            sudo cachyos-rate-mirrors --force
        else
            echo "Skipping mirror ranking."
        fi
    else
        echo "Running mirror ranking..."
        sudo cachyos-rate-mirrors --force
    fi
fi

# Install and run hardware detection tool
echo "Installing chwd for hardware optimization..."
paru -S --noconfirm --repo cachyos chwd
echo "Optimizing system..."
sudo chwd -a /

# Install all packages from appropriate repositories
echo "Installing packages..."

# Let pacman figure out which repository to use for CachyOS packages
# This will automatically use the correct repo (v3, v4, or znver4) based on what's configured
paru -S --noconfirm \
  cachyos-kernel-manager cachyos-hello cachyos-fish-config fish lapce zed

# Install from AUR
paru -S --noconfirm \
  opencode-bin

echo "Installation complete!"
echo "Use 'cachyos-kernel-manager' for kernels and 'fish' as shell."
