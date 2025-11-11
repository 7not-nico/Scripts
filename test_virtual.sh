#!/bin/bash

# Test version of CachyOS installation script
# This simulates the repository detection and conflict resolution logic

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to detect existing CachyOS repositories (test version)
detect_cachyos_repos() {
    local config_file="$1"
    local repos=()
    
    # Check for each possible CachyOS repository
    if grep -q "^\[cachyos\]" "$config_file"; then
        repos+=("cachyos")
    fi
    if grep -q "^\[cachyos-v3\]" "$config_file"; then
        repos+=("cachyos-v3")
    fi
    if grep -q "^\[cachyos-v4\]" "$config_file"; then
        repos+=("cachyos-v4")
    fi
    if grep -q "^\[cachyos-znver4\]" "$config_file"; then
        repos+=("cachyos-znver4")
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
            "cachyos-v3")
                has_v3=true
                ;;
            "cachyos-v4")
                has_v4=true
                ;;
            "cachyos-znver4")
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

# Function to simulate user interaction
simulate_user_choice() {
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
    
    # Simulate user choosing option 1 (replace)
    echo "SIMULATION: User chooses option 1 - Replace with $preferred_repo"
    return 1
}

# Function to check CPU support for optimal repository selection
detect_optimal_repo() {
    if /lib/ld-linux-x86-64.so.2 --help | grep -q "x86-64-v4 (supported, searched)"; then
        echo "cachyos-v4"
    else
        echo "cachyos-v3"
    fi
}

# Main test function
run_test() {
    local test_scenario="$1"
    local config_file="$2"
    local preferred_repo="$3"  # Pass optimal repo as parameter
    
    echo "=== TEST SCENARIO: $test_scenario ==="
    echo "Testing with config file: $config_file"
    echo
    
    # Detect existing repositories
    local existing_repos
    mapfile -t existing_repos < <(detect_cachyos_repos "$config_file")
    
    print_status "Detected repositories: ${existing_repos[*]}"
    print_status "Optimal repository: $preferred_repo"
    echo
    
    if [ ${#existing_repos[@]} -eq 0 ]; then
        # Scenario 1: No CachyOS repos
        print_status "SCENARIO 1: No CachyOS repos found"
        print_status "Action: Would install $preferred_repo automatically"
        
    elif [[ " ${existing_repos[*]} " =~ " ${preferred_repo} " ]]; then
        # Scenario 2: Optimal repo already exists
        print_status "SCENARIO 2: Optimal repository already configured"
        print_status "Action: Would keep as-is"
        
    elif check_repo_conflicts "${existing_repos[@]}"; then
        # Scenario 4: Conflicting repos exist
        print_status "SCENARIO 4: Conflicting repositories detected"
        simulate_user_choice "$preferred_repo" "${existing_repos[@]}"
        local choice=$?
        
        case $choice in
            1)  # Replace
                print_status "Action: Would backup and replace with $preferred_repo"
                ;;
            2)  # Keep
                print_status "Action: Would keep existing repositories"
                ;;
            3)  # Add alongside
                print_status "Action: Would add $preferred_repo alongside existing"
                ;;
            4)  # Cancel
                print_status "Action: Would cancel installation"
                ;;
        esac
        
    else
        # Scenario 3: Compatible repos exist
        print_status "SCENARIO 3: Compatible repositories exist"
        print_status "Action: Would add $preferred_repo alongside existing"
    fi
    
    echo
    echo "=== TEST COMPLETE ==="
    echo
}

# Create different test scenarios
echo "Creating test scenarios..."

# Scenario 1: No CachyOS repos
cat > test_no_repos.conf << 'EOF'
[options]
Architecture = auto

[core]
Server = https://mirror.archlinux.org/$repo/os/$arch

[extra]
Server = https://mirror.archlinux.org/$repo/os/$arch
EOF

# Scenario 2: Only optimal repo (v3)
cat > test_optimal_v3.conf << 'EOF'
[options]
Architecture = auto

[core]
Server = https://mirror.archlinux.org/$repo/os/$arch

[cachyos-v3]
Server = https://mirror.cachyos.org/$repo/v3/$arch
EOF

# Scenario 3: Conflicting repos (v3 and v4)
cat > test_conflicting.conf << 'EOF'
[options]
Architecture = auto

[core]
Server = https://mirror.archlinux.org/$repo/os/$arch

[cachyos-v3]
Server = https://mirror.cachyos.org/$repo/v3/$arch

[cachyos-v4]
Server = https://mirror.cachyos.org/$repo/v4/$arch
EOF

# Scenario 4: Compatible repos (base and v3)
cat > test_compatible.conf << 'EOF'
[options]
Architecture = auto

[core]
Server = https://mirror.archlinux.org/$repo/os/$arch

[cachyos]
Server = https://mirror.cachyos.org/$repo/$arch

[cachyos-v3]
Server = https://mirror.cachyos.org/$repo/v3/$arch
EOF

# Scenario 5: Only conflicting v4 repo (CPU doesn't support v4)
cat > test_v4_only.conf << 'EOF'
[options]
Architecture = auto

[core]
Server = https://mirror.archlinux.org/$repo/os/$arch

[cachyos-v4]
Server = https://mirror.cachyos.org/$repo/v4/$arch
EOF

# Detect optimal repo once
print_status "Checking CPU support for optimal repository selection..."
preferred_repo=$(detect_optimal_repo)
if [[ "$preferred_repo" == "cachyos-v4" ]]; then
    print_status "✅ CPU supports x86-64-v4 instruction set"
else
    print_status "❌ CPU does not support x86-64-v4, using v3"
fi

# Run all test scenarios
run_test "No CachyOS Repositories" "test_no_repos.conf" "$preferred_repo"
run_test "Optimal Repository Already Present" "test_optimal_v3.conf" "$preferred_repo"
run_test "Conflicting Repositories (v3 vs v4)" "test_conflicting.conf" "$preferred_repo"
run_test "Compatible Repositories (base + v3)" "test_compatible.conf" "$preferred_repo"
run_test "Suboptimal Repository Only (v4 when CPU supports v3)" "test_v4_only.conf" "$preferred_repo"

# Clean up test files
rm -f test_*.conf

echo "All test scenarios completed successfully!"