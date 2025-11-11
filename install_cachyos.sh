#!/bin/bash

# CachyOS Automated Installation Script - Improved Version
# Usage: ./install_cachyos.sh

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to create backup of pacman.conf
backup_pacman_conf() {
    local backup_file="/etc/pacman.conf.backup.$(date +%Y%m%d_%H%M%S)"
    if sudo cp /etc/pacman.conf "$backup_file"; then
        print_status "Backup created: $backup_file"
        echo "$backup_file"
    else
        print_error "Failed to create backup of pacman.conf"
        exit 1
    fi
}

# Function to detect existing CachyOS repositories
detect_cachyos_repos() {
    local repos=()
    
    # Check for each possible CachyOS repository
    if grep -q "^\[cachyos\]" /etc/pacman.conf; then
        repos+=("cachyos")
    fi
    if grep -q "^\[cachyos-v3\]" /etc/pacman.conf; then
        repos+=("cachyos-v3")
    fi
    if grep -q "^\[cachyos-v4\]" /etc/pacman.conf; then
        repos+=("cachyos-v4")
    fi
    if grep -q "^\[cachyos-znver4\]" /etc/pacman.conf; then
        repos+=("cachyos-znver4")
    fi
    
    # Also check for core/extra variants
    if grep -q "^\[cachyos-core-v3\]" /etc/pacman.conf; then
        repos+=("cachyos-core-v3")
    fi
    if grep -q "^\[cachyos-extra-v3\]" /etc/pacman.conf; then
        repos+=("cachyos-extra-v3")
    fi
    if grep -q "^\[cachyos-core-v4\]" /etc/pacman.conf; then
        repos+=("cachyos-core-v4")
    fi
    if grep -q "^\[cachyos-extra-v4\]" /etc/pacman.conf; then
        repos+=("cachyos-extra-v4")
    fi
    if grep -q "^\[cachyos-core-znver4\]" /etc/pacman.conf; then
        repos+=("cachyos-core-znver4")
    fi
    if grep -q "^\[cachyos-extra-znver4\]" /etc/pacman.conf; then
        repos+=("cachyos-extra-znver4")
    fi
    
    printf '%s\n' "${repos[@]}"
}

# Function to check for repository conflicts
check_repo_conflicts() {
    local existing_repos=("$@")
    local has_v3=false
    local has_v4=false
    local has_znver4=false
    
    for repo in "${existing_repos[@]}"; do
        case "$repo" in
            "cachyos-v3"|"cachyos-core-v3"|"cachyos-extra-v3")
                has_v3=true
                ;;
            "cachyos-v4"|"cachyos-core-v4"|"cachyos-extra-v4")
                has_v4=true
                ;;
            "cachyos-znver4"|"cachyos-core-znver4"|"cachyos-extra-znver4")
                has_znver4=true
                ;;
        esac
    done
    
    # Check for conflicts
    if ($has_v3 && $has_v4) || ($has_v3 && $has_znver4) || ($has_v4 && $has_znver4); then
        return 0  # Has conflicts
    fi
    
    return 1  # No conflicts
}

# Function to present existing repositories to user
present_existing_repos() {
    local existing_repos=("$@")
    
    print_status "Current CachyOS repositories found:"
    for repo in "${existing_repos[@]}"; do
        echo "  - $repo"
    done
}

# Function to ask user for conflict resolution
ask_conflict_resolution() {
    local preferred_repo="$1"
    local existing_repos=("$@")
    
    echo
    print_warning "Repository conflict detected!"
    present_existing_repos "${existing_repos[@]}"
    echo
    print_question "Your system supports $preferred_repo, but conflicting repositories are found."
    echo "Choose an option:"
    echo "1) Replace existing repositories with $preferred_repo (recommended)"
    echo "2) Keep current repositories (may not be optimal for your CPU)"
    echo "3) Add $preferred_repo alongside existing repositories (may cause conflicts)"
    echo "4) Cancel installation"
    echo
    
    while true; do
        read -p "Enter your choice [1-4]: " -n 1 -r
        echo
        case $REPLY in
            1)
                return 1  # Replace
                ;;
            2)
                return 2  # Keep
                ;;
            3)
                return 3  # Add alongside
                ;;
            4)
                return 4  # Cancel
                ;;
            *)
                echo "Please enter 1, 2, 3, or 4"
                ;;
        esac
    done
}

# Function to install CachyOS repository
install_cachyos_repo() {
    local repo_type="$1"
    
    print_status "Downloading CachyOS repository installer..."
    curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    
    case "$repo_type" in
        "cachyos-v4")
            print_status "Installing CachyOS v4 repositories..."
            sudo ./install-v4-repo.awk
            ;;
        "cachyos-v3")
            print_status "Installing CachyOS v3 repositories..."
            sudo ./install-repo.awk
            ;;
        *)
            print_error "Unknown repository type: $repo_type"
            cd -
            return 1
            ;;
    esac
    
    cd -
    print_status "Repository installation completed."
}

# Function to remove existing CachyOS repositories
remove_existing_repos() {
    print_status "Removing existing CachyOS repositories..."
    curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    sudo ./remove-repo.awk
    cd -
}

# Function to check CPU support for optimal repository selection
detect_optimal_repo() {
    print_status "Checking CPU support for optimal repository selection..." >&2
    
    if /lib/ld-linux-x86-64.so.2 --help | grep -q "x86-64-v4 (supported, searched)"; then
        print_status "✅ CPU supports x86-64-v4 instruction set" >&2
        echo "cachyos-v4"
    else
        print_status "❌ CPU does not support x86-64-v4, using v3" >&2
        echo "cachyos-v3"
    fi
}

# Main repository management logic
manage_repositories() {
    local preferred_repo
    preferred_repo=$(detect_optimal_repo)
    
    # Detect existing repositories
    local existing_repos
    mapfile -t existing_repos < <(detect_cachyos_repos)
    
    if [ ${#existing_repos[@]} -eq 0 ]; then
        # Scenario 1: No CachyOS repos
        print_status "No CachyOS repositories found. Installing $preferred_repo..." >&2
        backup_pacman_conf >/dev/null
        install_cachyos_repo "$preferred_repo" >/dev/null
        
    elif [[ " ${existing_repos[*]} " =~ " ${preferred_repo} " ]]; then
        # Scenario 2: Optimal repo already exists
        print_status "Optimal repository $preferred_repo already configured." >&2
        
    elif check_repo_conflicts "${existing_repos[@]}"; then
        # Scenario 4: Conflicting repos exist
        ask_conflict_resolution "$preferred_repo" "${existing_repos[@]}" >&2
        local choice=$?
        
        case $choice in
            1)  # Replace
                backup_pacman_conf >/dev/null
                remove_existing_repos
                install_cachyos_repo "$preferred_repo" >/dev/null
                ;;
            2)  # Keep
                print_warning "Keeping existing repositories as requested." >&2
                print_warning "Note: Your system may not be using the optimal repository." >&2
                preferred_repo="existing"  # Use existing repos for package installation
                ;;
            3)  # Add alongside
                backup_pacman_conf >/dev/null
                install_cachyos_repo "$preferred_repo" >/dev/null
                ;;
            4)  # Cancel
                print_error "Installation cancelled by user." >&2
                exit 0
                ;;
        esac
        
    else
        # Scenario 3: Compatible repos exist, add optimal repo
        print_status "Adding $preferred_repo alongside existing repositories..." >&2
        backup_pacman_conf >/dev/null
        install_cachyos_repo "$preferred_repo" >/dev/null
    fi
    
    echo "$preferred_repo"
}

# Function to install paru if not present
install_paru() {
    if ! command -v paru &> /dev/null; then
        print_status "Installing paru AUR helper..."
        yay -S --noconfirm paru
    else
        print_status "paru already installed."
    fi
}

# Function to manage cachyos-rate-mirrors
manage_mirror_ranking() {
    if ! command -v cachyos-rate-mirrors &> /dev/null; then
        print_status "Installing cachyos-rate-mirrors..."
        paru -S --noconfirm cachyos-rate-mirrors
        print_status "Running mirror ranking..."
        sudo cachyos-rate-mirrors --force
    else
        print_status "cachyos-rate-mirrors already installed."
        
        # Check if mirrors have been ranked before
        local arch_mirrorlist="/etc/pacman.d/mirrorlist"
        local cachyos_mirrorlist="/etc/pacman.d/cachyos-mirrorlist"
        
        local mirrors_ranked=false
        if [[ -f "$arch_mirrorlist" ]] && grep -q "Server = https://.*archlinux" "$arch_mirrorlist"; then
            if [[ -f "$cachyos_mirrorlist" ]] && grep -q "Server = https://.*cachyos" "$cachyos_mirrorlist"; then
                mirrors_ranked=true
            fi
        fi
        
        if $mirrors_ranked; then
            print_status "Mirror ranking has been run before."
            read -p "Do you want to run mirror ranking again? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Running mirror ranking..."
                sudo cachyos-rate-mirrors --force
            else
                print_status "Skipping mirror ranking."
            fi
        else
            print_status "Running mirror ranking..."
            sudo cachyos-rate-mirrors --force
        fi
    fi
}

# Function to install hardware detection tool
install_hardware_detection() {
    local repo="$1"
    print_status "Installing chwd for hardware optimization..."
    paru -S --needed --noconfirm chwd
    print_status "Optimizing system..."
    if ! sudo chwd -a; then
        print_warning "Hardware optimization encountered dependency conflicts."
        print_status "This is normal on some systems. Continuing with installation..."
    fi
}

# Function to install packages
install_packages() {
    local repo="$1"
    print_status "Installing packages from $repo..."
    
    # Remove conflicting tldr package only (mesa is critical for system)
    if pacman -Qi tldr &>/dev/null; then
        print_status "Removing conflicting tldr package..."
        echo "y" | sudo pacman -R tldr
    fi
    
    # CachyOS packages - use paru's automatic conflict resolution
    print_status "Installing CachyOS packages..."
    paru -S --needed --ask=4 \
      cachyos-kernel-manager cachyos-hello cachyos-fish-config fish lapce zed octopi || true
    
    # AUR packages - use --needed to skip already installed packages
    paru -S --needed --noconfirm opencode-bin || true
}

# Function to remove orphan packages
remove_orphans() {
    print_status "Checking for orphan packages..."
    
    # Get list of orphans
    local orphans=$(pacman -Qtdq)
    
    if [ -n "$orphans" ]; then
        print_status "Removing orphan packages..."
        if sudo pacman -Rns $orphans 2>/dev/null; then
            print_status "Orphan packages removed successfully."
        else
            print_warning "Some orphan packages could not be removed."
        fi
    else
        print_status "No orphan packages found."
    fi
}

###UPDATE, WE NEED TO MAKE IT LAUNCH cachyos-hello after it has finish the script succefully

# Function to launch cachyos-hello with enhanced user experience and conditional launch
launch_cachyos_hello_if_desired() {
    # Check if cachyos-hello command exists
    if ! command -v cachyos-hello &> /dev/null; then
        print_warning "cachyos-hello not found - installation may have failed."
        return 1
    fi
    
    # Check if cachyos-hello is already running
    if pgrep -f "cachyos-hello" > /dev/null; then
        print_warning "cachyos-hello appears to be already running."
        print_status "You can run it manually when the current instance finishes."
        return 0
    fi
    
    echo
    print_status "cachyos-hello is the CachyOS welcome and setup wizard."
    print_status "It helps configure your system with recommended settings."
    echo
    
    # Enhanced user experience - ask user if they want to launch
    print_question "Would you like to launch cachyos-hello now? [Y/n]: "
    read -p "" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "You can run cachyos-hello anytime from the terminal by typing 'cachyos-hello'."
        return 0
    fi
    
    # Conditional launch with error handling
    print_status "Launching cachyos-hello..."
    print_info "Note: You can exit cachyos-hello at any time with Ctrl+C"
    echo
    
    # Launch cachyos-hello and handle the result
    if cachyos-hello; then
        echo
        print_status "cachyos-hello completed successfully."
        print_status "Your CachyOS system is now optimally configured!"
    else
        echo
        local exit_code=$?
        if [ $exit_code -eq 130 ]; then
            print_status "cachyos-hello was cancelled by user (Ctrl+C)."
            print_status "You can run it again anytime with 'cachyos-hello'."
        else
            print_warning "cachyos-hello encountered an error (exit code: $exit_code)."
            print_status "You can try running it manually or check the logs for details."
        fi
    fi
}

# Main execution
main() {
    print_status "Starting CachyOS installation..."
    
    # Step 1: Manage repositories
    local active_repo
    active_repo=$(manage_repositories)
    
    # Step 2: Install paru
    install_paru
    
    # Step 3: Manage mirror ranking
    manage_mirror_ranking
    
    # Step 4: Install hardware detection
    install_hardware_detection "$active_repo"
    
    # Step 5: Install packages
    install_packages "$active_repo"
    
    # Step 6: Remove orphan packages
    remove_orphans
    
    print_status "Installation complete!"
    print_status "Use 'cachyos-kernel-manager' for kernels and 'fish' as shell."
    
    # Enhanced user experience + conditional launch for cachyos-hello
    launch_cachyos_hello_if_desired
}

# Run main function
main "$@"
