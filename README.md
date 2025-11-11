# CachyOS Scripts

Fast setup scripts for CachyOS Linux.

## Scripts

### `install_cachyos.sh`
Simple system installation with update-then-restart workflow.

### `complexver`
Advanced installation with CPU detection and repo optimization.

### `rate-mirrors.sh`
Mirror optimization + package installation (fish, octopi, zen-browser-bin).

## Online Execution

Click the copy icon (📋) in the top-right of each code block:

```bash
# Simple installation
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/install_cachyos.sh)
```

```bash
# Complex installation
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/complexver)
```

```bash
# Mirror setup only
bash <(curl -s https://raw.githubusercontent.com/7not-nico/Scripts/main/rate-mirrors.sh)
```

## Quick Start

```bash
# Simple installation
./install_cachyos.sh

# Complex installation
./complexver

# Mirror setup only
./rate-mirrors.sh
```

## Features

- Auto system updates
- Mirror optimization with cachyos-rate-mirrors
- Package installation with paru
- KISS principle - simple, direct, stupid
