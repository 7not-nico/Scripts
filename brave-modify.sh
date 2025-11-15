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

print_status "Done. Restart Brave to apply changes."