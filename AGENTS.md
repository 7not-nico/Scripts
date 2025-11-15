# AGENTS.md - CachyOS Scripts Development

## Commands
```bash
# Syntax check all scripts
bash -n *.sh

# Test single script
bash -n rate-mirrors.sh

# Test AWK scripts
awk -f cachyos-repo/install-repo.awk /etc/pacman.conf
```

## Code Style
- Bash: `set -e`, `snake_case()` functions, `local` variables
- Use `print_status()` with GREEN/NC colors for output
- KISS principle - simple, direct, minimal complexity
- Standardize on `paru-bin` for AUR package management
- Use `--needed --noconfirm` flags for package installation

## Error Handling
- Check command exit codes, clear error messages
- Exit codes: 0 success, 1 error
- Use `|| true` for non-critical failures
- Wrap critical commands in error handling blocks

## Package Management
- Use `paru -S --needed --noconfirm` for AUR packages
- Install `paru-bin` with fallback to makepkg if needed
- Always push changes to git after modifications

## Testing
- Test script syntax with `bash -n`
- Verify online execution with curl/bash pipes
- Test package installation workflows

## Common Errors and Fixes
- **Ruby `gets` Error**: When `gets` fails with "No such file or directory" on arguments, change `gets` to `STDIN.gets` to read from stdin instead of ARGF (which treats args as files).
- **Selector Outdated**: For web scraping, re-inspect site HTML and update CSS selectors if site changes (e.g., Anna's Archive torrent links).