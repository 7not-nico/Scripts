# CachyOS Repository Management

Scripts for adding and removing CachyOS repositories, which provide performance-optimized packages and kernels for x86-64, x86-64-v3, x86-64-v4, and Zen4 architectures.

## Overview

CachyOS provides repositories with optimized packages for better performance. These scripts automatically detect your CPU's ISA level and add the appropriate repository.

## Scripts

- `cachyos-repo.sh`: Main bash script to install or remove CachyOS repositories
- `install-repo.awk`: AWK script to add standard CachyOS (x86-64-v3) repository
- `install-v4-repo.awk`: AWK script to add x86-64-v4 optimized repository
- `install-znver4-repo.awk`: AWK script to add Zen4 optimized repository
- `remove-repo.awk`: AWK script to remove CachyOS repositories

## Usage

### Using the Bash Script (Recommended)

```bash
# Install CachyOS repo (auto-detects CPU)
sudo ./cachyos-repo.sh --install

# Remove CachyOS repo
sudo ./cachyos-repo.sh --remove

# Show help
./cachyos-repo.sh --help
```

### Using AWK Scripts Directly

```bash
# Add standard repo
sudo awk -f install-repo.awk /etc/pacman.conf

# Add v4 repo
sudo awk -f install-v4-repo.awk /etc/pacman.conf

# Add Zen4 repo
sudo awk -f install-znver4-repo.awk /etc/pacman.conf

# Remove repo
sudo awk -f remove-repo.awk /etc/pacman.conf
```

## Features

- Automatic CPU ISA level detection
- Backup of original pacman.conf
- Keyring and mirrorlist installation
- Support for multiple architectures
- Safe removal with package reinstallation

## Requirements

- Root access (sudo)
- pacman.conf file present
- Internet connection for key and package downloads

## Notes

- The script installs CachyOS keyring and mirrorlists
- Automatically selects the best repository based on CPU capabilities
- Creates backup of pacman.conf before modifications
- For more info, see [CachyOS repositories](https://github.com/CachyOS/linux-cachyos)
