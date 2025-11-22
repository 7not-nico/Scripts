#!/bin/bash

# System Update Script using Paru
# This script updates your Omarchy system using paru package manager

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for system operations
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo privileges for system operations."
        sudo -v || {
            print_error "Failed to obtain sudo privileges."
            exit 1
        }
    fi
}

# Main update function
update_system() {
    print_status "Starting system update..."
    
    # Refresh package databases
    print_status "Refreshing package databases..."
    if ! paru -Syy; then
        print_error "Failed to refresh package databases."
        exit 1
    fi
    
    # Update system packages
    print_status "Updating system packages..."
    if paru -Su --noconfirm; then
        print_success "System updated successfully!"
    else
        print_warning "Update completed with some warnings. Check the output above."
    fi
    
    # Clean up orphan packages
    print_status "Cleaning up orphan packages..."
    if [[ $(paru -Qtdq) ]]; then
        paru -Rns $(paru -Qtdq) --noconfirm
        print_success "Orphan packages removed."
    else
        print_status "No orphan packages found."
    fi
    
    # Clear package cache (keep last 3 versions)
    print_status "Cleaning package cache..."
    paru -Scc --noconfirm
    print_success "Package cache cleaned."
}

# Check for failed transactions and retry
retry_failed_update() {
    print_status "Checking for failed transactions..."
    
    # Remove any partial downloads
    if [ -d "/var/cache/pacman/pkg" ]; then
        sudo find /var/cache/pacman/pkg -name "*.part" -delete 2>/dev/null || true
    fi
    
    # Retry the update
    update_system
}

# Main execution
main() {
    echo "========================================"
    echo "    Omarchy System Update Script       "
    echo "========================================"
    echo
    
    # Check if paru is installed
    if ! command -v paru &> /dev/null; then
        print_error "paru is not installed. Please install it first."
        exit 1
    fi
    
    # Check sudo access
    check_sudo
    
    # Check if we're in a recovery situation
    if [ "$1" = "--retry" ]; then
        retry_failed_update
    else
        update_system
    fi
    
    echo
    print_success "Update process completed!"
    echo "Press any key to continue..."
    read -n 1
}

# Handle script arguments
case "$1" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --retry    Retry update after a failed transaction"
        echo "  --help     Show this help message"
        exit 0
        ;;
    --retry)
        main --retry
        ;;
    *)
        main
        ;;
esac