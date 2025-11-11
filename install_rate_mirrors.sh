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

# Main function
main() {
    print_status "Installing cachyos-rate-mirrors..."
    sudo pacman -S --needed --noconfirm cachyos-rate-mirrors
    
    print_status "Running cachyos-rate-mirrors..."
    sudo cachyos-rate-mirrors
    
    print_status "Mirror rating complete!"
}

main "$@"