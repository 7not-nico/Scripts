# Troubleshooting Guide

Quick solutions for common CachyOS installation issues.

## Quick Reference

| Error | Solution |
|-------|----------|
| `target not found: cachyos-v3` | Remove --repo flag |
| `up to date -- reinstalling` | Add --needed flag |
| `unresolvable package conflicts` | Use --ask=4 flag |
| `script failed!` | Add error handling |
| `yay not found` | Script installs yay automatically |
| `system requires restart` | Restart and run script again |

## Common Issues and Solutions

### 1. System Update Issues

**Symptoms:**
- `yay: command not found`
- Script exits after applying updates
- "Please restart your system and run this script again"

**Solutions:**

#### Yay not found:
```bash
# Script installs yay automatically, but if it fails:
sudo pacman -S --needed --noconfirm yay
```

#### Update requires restart:
```bash
# This is normal behavior - restart and run script again:
sudo reboot
./install_cachyos.sh
```

#### Update fails:
```bash
# Manual update check
yay -Syu --noconfirm

# Or use pacman instead
sudo pacman -Syu --noconfirm
```

### 2. Repository Variable Capture Problems

**Symptoms:**
- `error: target not found: [INFO] Checking CPU support...`
- Package names contain status messages

**Solution:**
```bash
# Ensure functions redirect status to stderr
print_status "Message" >&2  # Add >&2
echo "return_value"         # Only this goes to stdout
```

**Debug Command:**
```bash
result=$(manage_repositories 2>/dev/null)
echo "Result: '$result'"
```

### 3. Package Installation Failures

**Symptoms:**
- `error: target not found: cachyos-v3`
- Package not found errors
- `dropbox`, `zen-browser-bin`, or `shortwave` installation failures

**Solution:**
```bash
# Remove --repo flag, let paru find packages
paru -S --needed --noconfirm package_name

# For AUR packages like zen-browser-bin and shortwave:
paru -S --needed --noconfirm zen-browser-bin shortwave || true

# For official packages like dropbox:
paru -S --needed --ask=4 dropbox || true
```

### 3. Dependency Conflicts

**Symptoms:**
- `error: unresolvable package conflicts detected`
- `tealdeer and tldr are in conflict`
- `mesa-git and mesa are in conflict`

**Solutions:**

#### For tldr/tealdeer conflict:
```bash
# Remove tldr before installing tealdeer
if pacman -Qi tldr &>/dev/null; then
    echo "y" | sudo pacman -R tldr
fi
```

#### For mesa/mesa-git conflict:
```bash
# DON'T remove mesa (critical for Hyprland)
# Use automatic conflict resolution instead
paru -S --needed --ask=4 package_name || true
```

### 4. Hardware Optimization Failures

**Symptoms:**
- `ERROR: Pacman command was failed! Exit code: 1`
- GStreamer dependency conflicts
- Graphics driver installation failures

**Solution:**
```bash
# Add error handling to hardware optimization
if ! sudo chwd -a; then
    print_warning "Hardware optimization encountered conflicts"
    print_status "This is normal on some systems. Continuing..."
fi
```

**Note:** This is normal on systems with existing graphics drivers.

### 5. Provider Selection Prompts

**Symptoms:**
- `:: There are 2 providers available for netcat:`
- `:: There are 26 providers available for vulkan-driver:`
- Script stops waiting for user input

**Solution:**
```bash
# Use --ask=4 to automatically select first provider
paru -S --needed --ask=4 package_name
```

### 6. Script Exits Unexpectedly

**Symptoms:**
- Script stops at first error
- `set -e` causing premature exit

**Solution:**
```bash
# Add || true to continue on failures
command_that_might_fail || true

# Or use proper error handling
if ! command; then
    echo "Command failed, but continuing..."
fi
```

## System-Specific Issues

### Hyprland Systems
**Problem:** Mesa removal breaks desktop environment
**Solution:** Never remove mesa, use conflict resolution instead

### Intel Graphics Systems
**Problem:** GStreamer conflicts during hardware optimization
**Solution:** Add error handling, conflicts are normal

### Systems with Existing Packages
**Problem:** Package conflicts with existing installations
**Solution:** Use `--needed` and `--ask=4` flags

## Debug Commands

### Check Repository Configuration
```bash
# List configured CachyOS repositories
grep -E "^\[cachyos" /etc/pacman.conf

# Test repository access
paru -Ss cachyos-kernel-manager
```

### Test Package Installation
```bash
# Test single package installation
paru -S --needed --ask=4 --noconfirm cachyos-hello

# Check if package is installed
pacman -Qi package_name
```

### Debug Script Functions
```bash
# Test repository detection
detect_optimal_repo

# Test repository management
manage_repositories

# Test with clean output
result=$(manage_repositories 2>/dev/null)
echo "Clean result: '$result'"
```

### Check Hardware Detection
```bash
# Test CPU detection
/lib/ld-linux-x86-64.so.2 --help | grep -q "x86-64-v4"

# Test chwd installation
sudo chwd -a
```

## Prevention Tips

### 1. Before Running Script
```bash
# Update package databases
sudo pacman -Sy

# Check for existing conflicts
pacman -Qs mesa
pacman -Qs tldr
```

### 2. During Installation
- Let the script handle conflicts automatically
- Don't interrupt the process
- Note any warnings for later review

### 3. After Installation
```bash
# Check installed packages
pacman -Qs cachyos

# Verify hardware optimization
sudo chwd -a

# Test cachyos-hello
cachyos-hello
```

## When to Seek Help

### Red Flags (Stop and Get Help)
- Script removes critical system packages (mesa, systemd, etc.)
- Multiple package installation failures
- Desktop environment stops working

### Normal Warnings (Continue)
- Hardware optimization conflicts
- Individual package installation failures
- Provider selection prompts (if script handles them)

### Collect Debug Information
```bash
# Save installation log
./install_cachyos.sh 2>&1 | tee installation.log

# Check system state
pacman -Qs mesa
pacman -Qs cachyos
ls /etc/pacman.d/
```

## Recovery Commands

### If Installation Fails Midway
```bash
# Restore pacman.conf backup
sudo cp /etc/pacman.conf.backup.* /etc/pacman.conf

# Update package databases
sudo pacman -Sy

# Reinstall critical packages
sudo pacman -S mesa hyprland
```

### If Desktop Environment Breaks
```bash
# Reinstall graphics drivers
sudo pacman -S mesa vulkan-intel

# Reinstall desktop environment
sudo pacman -S hyprland aquamarine

# Restart display manager
sudo systemctl restart display-manager
```

Some conflicts (graphics drivers) are normal and handled by script.

## Orphan Package Issues

### Orphan Removal Fails
**Symptoms:**
- "Some orphan packages could not be removed"
- Orphan packages remain after installation

**Solutions:**
```bash
# Manual orphan removal
sudo pacman -Rns $(pacman -Qtdq)

# Check what orphans exist
pacman -Qtdq

# Force remove specific orphans
sudo pacman -Rdd orphan_package_name
```

### No Orphans Found
**Symptoms:**
- "No orphan packages found" message
- Expected orphans but none detected

**Solutions:**
```bash
# Check all packages
pacman -Q

# Look for unneeded dependencies
paccache -r

# Clean package cache
sudo pacman -Scc
```

Some conflicts (graphics drivers) are normal and handled by script.