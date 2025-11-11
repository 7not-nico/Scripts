#!/bin/bash

# CachyOS Automated Installation Script
# Usage: ./install_cachyos.sh

set -e

# Check if CachyOS repos are already configured
if ! grep -q "cachyos\|cachyos-v3\|cachyos-v4" /etc/pacman.conf; then
    echo "CachyOS repos not found. Setting up repository..."
    # Download and setup CachyOS repository
    curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    sudo ./cachyos-repo.sh --install
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
    echo "cachyos-rate-mirrors already installed. Running mirror ranking..."
    sudo cachyos-rate-mirrors --force
fi

# Install and run hardware detection tool
echo "Installing chwd for hardware optimization..."
paru -S --noconfirm --repo cachyos-v3 chwd
echo "Optimizing system..."
sudo chwd -a /

# Install all packages from CachyOS v3 repo
echo "Installing packages..."
paru -S --noconfirm --repo cachyos-v3 \
  cachyos-kernel-manager cachyos-hello \
  opencode-bin fish cachyos-fish-config \
  lapce zed

echo "Installation complete!"
echo "Use 'cachyos-kernel-manager' for kernels and 'fish' as shell."
