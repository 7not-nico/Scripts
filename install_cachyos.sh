#!/bin/bash

# CachyOS Automated Installation Script
# Usage: ./install_cachyos.sh

set -e

# Check if CachyOS repos are already configured
if ! grep -q "cachyos\|cachyos-v3\|cachyos-v4\|cachyos-znver4" /etc/pacman.conf; then
    echo "CachyOS repos not found. Setting up repository..."
    # Download and setup CachyOS repository
    curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    sudo ./cachyos-repo.sh --install
    cd -
else
    echo "CachyOS repos already configured."
fi

# Determine which CachyOS repository is configured and active
ACTIVE_CACHYOS_REPO=""
if grep -q "^\[cachyos-v3\]" /etc/pacman.conf && ! grep -q "^\[cachyos-v3\]" /etc/pacman.conf | grep -q "#"; then
    ACTIVE_CACHYOS_REPO="cachyos-v3"
elif grep -q "^\[cachyos-v4\]" /etc/pacman.conf && ! grep -q "^\[cachyos-v4\]" /etc/pacman.conf | grep -q "#"; then
    ACTIVE_CACHYOS_REPO="cachyos-v4"
elif grep -q "^\[cachyos-znver4\]" /etc/pacman.conf && ! grep -q "^\[cachyos-znver4\]" /etc/pacman.conf | grep -q "#"; then
    ACTIVE_CACHYOS_REPO="cachyos-znver4"
elif grep -q "^\[cachyos\]" /etc/pacman.conf && ! grep -q "^\[cachyos\]" /etc/pacman.conf | grep -q "#"; then
    ACTIVE_CACHYOS_REPO="cachyos"
fi

echo "Active CachyOS repository detected: $ACTIVE_CACHYOS_REPO"

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

# Install from the active CachyOS repository (v3, v4, or znver4)
if [[ -n "$ACTIVE_CACHYOS_REPO" ]]; then
    echo "Installing from $ACTIVE_CACHYOS_REPO..."
    paru -S --noconfirm --repo "$ACTIVE_CACHYOS_REPO" \
      cachyos-kernel-manager cachyos-hello
else
    echo "Warning: Could not detect active CachyOS repository, trying cachyos-v3..."
    paru -S --noconfirm --repo cachyos-v3 \
      cachyos-kernel-manager cachyos-hello
fi

# Install from cachyos repo (base repo)
paru -S --noconfirm --repo cachyos \
  cachyos-fish-config

# Install from appropriate extra repository based on active repo
if [[ "$ACTIVE_CACHYOS_REPO" == "cachyos-v4" ]]; then
    paru -S --noconfirm --repo cachyos-extra-v4 \
      fish
elif [[ "$ACTIVE_CACHYOS_REPO" == "cachyos-znver4" ]]; then
    paru -S --noconfirm --repo cachyos-extra-znver4 \
      fish
else
    # Default to cachyos-extra-v3
    paru -S --noconfirm --repo cachyos-extra-v3 \
      fish
fi

# Install from extra repo
paru -S --noconfirm --repo extra \
  lapce zed

# Install from AUR
paru -S --noconfirm \
  opencode-bin

echo "Installation complete!"
echo "Use 'cachyos-kernel-manager' for kernels and 'fish' as shell."
