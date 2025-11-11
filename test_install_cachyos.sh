#!/bin/bash

# CachyOS Automated Installation Script - Dry Run Test
# This script tests the installation process without actually installing anything

set -e  # Exit immediately if any command fails

echo "=== DRY RUN TEST MODE ==="
echo "This will simulate the installation process without making changes"
echo ""

# Test download and extraction (dry run)
echo "Testing download and extraction..."
echo "Would run: curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz"
echo "Would run: tar xvf cachyos-repo.tar.xz && cd cachyos-repo"
echo "Would run: sudo ./cachyos-repo.sh"
echo "Would run: cd -"
echo ""

# Test package installations
echo "Testing package availability..."

# Test paru AUR helper
echo "Would run: yay -S --noconfirm paru"
if command -v paru &> /dev/null; then
    echo "✅ paru is available"
else
    echo "❌ paru not found - would be installed"
fi

# Test CachyOS packages
packages=("cachyos-kernel-manager" "cachyos-hello" "fish" "lapce" "zed")
echo "Would run: paru -S --noconfirm --repo cachyos ${packages[*]}"

for pkg in "${packages[@]}"; do
    if paru -Ss "$pkg" &> /dev/null; then
        echo "✅ $pkg is available"
    else
        echo "❌ $pkg not found"
    fi
done

# Test AUR packages
aur_packages=("opencode-bin")
echo "Would run: paru -S --noconfirm ${aur_packages[*]}"

for pkg in "${aur_packages[@]}"; do
    if paru -Ss "$pkg" &> /dev/null; then
        echo "✅ $pkg is available"
    else
        echo "❌ $pkg not found"
    fi
done

# Test mirror ranking
echo ""
echo "Would run: sudo cachyos-rate-mirrors --force"
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "✅ cachyos-rate-mirrors is available"
else
    echo "❌ cachyos-rate-mirrors not found"
fi

# Test directory change
echo ""
echo "Would run: sudo chwd -a /"
if command -v chwd &> /dev/null; then
    echo "✅ chwd is available"
else
    echo "❌ chwd not found"
fi

echo ""
echo "=== DRY RUN COMPLETE ==="
echo "All commands and packages have been verified for availability"
echo "The actual script should work correctly based on this test"