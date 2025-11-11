# CachyOS Scripts

Fast setup scripts for CachyOS Linux.

## Scripts

### `install_cachyos.sh`
Full system installation with update-then-restart workflow.

### `install_rate_mirrors.sh`
Mirror optimization + package installation with repo priority.

## Quick Start

```bash
# Full installation
./install_cachyos.sh

# Mirror setup only
./install_rate_mirrors.sh
```

## Features

- Auto system updates
- Repo priority: *v4 → *v3 → cachyos*
- User fallback for missing packages
- KISS principle - simple, direct, stupid
