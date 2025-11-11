#!/bin/bash

# CachyOS Automated Installation Script
# Usage: ./install_cachyos.sh

set -e

# Download and setup CachyOS repository
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
echo "y" | sudo ./cachyos-repo.sh
cd -

# Install paru AUR helper
echo "Installing paru..."
echo "y" | yay -S --noconfirm paru

# Install and run mirror ranking tool
echo "Installing cachyos-rate-mirrors..."
echo "y" | paru -S --noconfirm cachyos-rate-mirrors
echo "Running mirror ranking..."
echo "y" | cachyos-rate-mirrors

# Optimize system for hardware
echo "Optimizing system..."
sudo chwd -a /

# Install all packages from CachyOS v3 repo
echo "Installing packages..."
echo "y" | paru -S --noconfirm --repo cachyos-v3 \
  cachyos-kernel-manager cachyos-hello \
  opencode-bin fish cachyos-fish-config \
  lapce zed

echo "Installation complete!"
echo "Use 'cachyos-kernel-manager' for kernels and 'fish' as shell."
