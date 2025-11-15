#!/bin/bash          # Shebang: specifies bash interpreter
set -e               # Exit on any error

# Color output following AGENTS.md
GREEN='\033[0;32m'   # Variable assignment with ANSI color code
NC='\033[0m'         # No Color reset

print_status() {     # Function definition
    echo -e "${GREEN}[INFO]${NC} $1"  # echo with -e for escape sequences, variable expansion
}

# Install Ruby if missing
if ! command -v ruby &> /dev/null; then  # Conditional: ! negates, command -v checks existence, &> redirects both stdout/stderr
    print_status "Installing Ruby..."
    paru -S --needed --noconfirm ruby  # Command execution with flags
fi

# Execute Ruby script
print_status "Modifying Brave Local State..."
ruby <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/brave-script/modify_local_state.rb)  # Process substitution <() pipes curl output to ruby

# Launch Brave browser
if command -v brave &> /dev/null; then
    print_status "Launching Brave browser..."
    nohup brave > /dev/null 2>&1 &  # nohup prevents hangup, > redirects stdout, 2>&1 redirects stderr to stdout, & backgrounds process
    print_status "Brave launched successfully. Experimental features are now active."
elif command -v brave-browser &> /dev/null; then  # elif for alternative condition
    print_status "Launching Brave browser..."
    nohup brave-browser > /dev/null 2>&1 &
    print_status "Brave launched successfully. Experimental features are now active."
else  # Fallback condition
    print_status "Brave browser not found in PATH. Please launch manually to apply changes."
fi