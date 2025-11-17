# CachyOS Repository Management

Advanced scripts for adding and removing CachyOS repositories, providing performance-optimized packages and kernels for x86-64, x86-64-v3, x86-64-v4, and Zen4 architectures.

## Overview

CachyOS repositories contain packages compiled with specific CPU optimizations for better performance. These scripts automatically detect your CPU's ISA level and configure the appropriate repository with safety features and rollback capabilities.

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
sudo ./cachyos-repo/cachyos-repo.sh --install

# Remove CachyOS repo
sudo ./cachyos-repo/cachyos-repo.sh --remove

# Show help
./cachyos-repo/cachyos-repo.sh --help
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

- **Automatic CPU Detection**: Intelligent ISA level detection (x86-64, v3, v4, Zen4)
- **Safe Operations**: Automatic backup of pacman.conf before modifications
- **Complete Setup**: Keyring and mirrorlist installation included
- **Multi-Architecture**: Support for all optimization levels
- **Safe Removal**: Package reinstallation when removing repositories
- **Error Handling**: Comprehensive error checking and user feedback
- **Rollback Support**: Easy restoration from backups if needed

## Requirements

- Root access (sudo privileges)
- Standard pacman.conf file present
- Internet connection for keyring and package downloads
- Compatible with Arch Linux and CachyOS systems

## Advanced Usage

### CPU Detection Logic

The scripts use `/lib/ld-linux-x86-64.so.2 --help` to detect CPU capabilities:
- **x86-64-v3**: AVX2, BMI2, FMA support
- **x86-64-v4**: AVX512 support  
- **Zen4**: AMD Zen4 specific optimizations

### Manual Repository Selection

Override automatic detection:
```bash
# Force specific repository
REPO_TYPE=v4 sudo ./cachyos-repo.sh --install
REPO_TYPE=znver4 sudo ./cachyos-repo.sh --install
```

### Backup and Restore

```bash
# View available backups
ls -la /etc/pacman.conf.backup.*

# Restore from backup
sudo cp /etc/pacman.conf.backup.YYYYMMDD_HHMMSS /etc/pacman.conf
```

## Troubleshooting

### Common Issues

1. **GPG Key Errors**: Update keyring with `sudo pacman -Sy archlinux-keyring cachyos-keyring`
2. **Mirror Issues**: Refresh mirrorlist with `sudo pacman -Syy`
3. **Permission Denied**: Ensure running with sudo for repository operations

### Debug Mode

Enable verbose output:
```bash
DEBUG=1 sudo ./cachyos-repo.sh --install
```

## Notes

- Scripts install CachyOS keyring and mirrorlists automatically
- Repository selection based on CPU capabilities for optimal performance
- Creates timestamped backups of pacman.conf before any modifications
- Compatible with package managers: pacman, paru, yay
- For detailed information, see [CachyOS repositories](https://github.com/CachyOS/linux-cachyos)
