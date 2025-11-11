# AGENTS.md - CachyOS Scripts Development

## Commands
```bash
# Syntax check
bash -n install_cachyos.sh

# Test AWK scripts
awk -f cachyos-repo/install-repo.awk /etc/pacman.conf
```

## Code Style
- Bash: `set -e`, `snake_case()` functions, `local` variables
- Use `print_status()`, `print_warning()`, `print_error()` for output
- Redirect status messages to stderr in functions that return values
- AWK: Follow GNU license header, use BEGIN/END blocks

## Error Handling
- Check command exit codes, clear error messages
- Create backups before system changes
- Exit codes: 0 success, 1 error
- Use `|| true` to continue on non-critical failures
- Wrap critical commands in error handling blocks

## Package Installation
- Use `--needed` flag to skip already installed packages
- Use `--ask=4` for automatic conflict resolution
- Remove `--repo` flags, let paru find packages automatically
- Preserve critical system packages (mesa for Hyprland)

## Repository Management
- Detect existing repos before changes
- Get user consent for destructive operations
- Return only repo names from functions (redirect other output)
- Handle v3/v4/znver4 conflicts

## Testing
- Test all repo scenarios (no repos, optimal, compatible, conflicting)
- Verify backup creation, user interaction flows, CPU detection
- Test hardware optimization conflict handling