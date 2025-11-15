#!/bin/bash
set -e

# Color output following AGENTS.md
GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Install Ruby if missing
if ! command -v ruby &> /dev/null; then
    print_status "Installing Ruby..."
    paru -S --needed --noconfirm ruby
fi

# Execute Ruby script
print_status "Modifying Brave Local State..."
ruby <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/brave-script/modify_local_state.rb)

# Launch Brave browser
if command -v brave &> /dev/null; then
    print_status "Launching Brave browser..."
    nohup brave > /dev/null 2>&1 &
    print_status "Brave launched successfully. Experimental features are now active."
elif command -v brave-browser &> /dev/null; then
    print_status "Launching Brave browser..."
    nohup brave-browser > /dev/null 2>&1 &
    print_status "Brave launched successfully. Experimental features are now active."
else
    print_status "Brave browser not found in PATH. Please launch manually to apply changes."
fi