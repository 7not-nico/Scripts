#!/usr/bin/env python3
import os
import subprocess
import fnmatch
from pathlib import Path

# Configuration
HOME = Path.home()
CONFIG_DIR = HOME / ".config" / "gzdoom"
DIRS = {
    "iwad": CONFIG_DIR / "iwad",
    "pk3": CONFIG_DIR / "pk3",
    "wad": CONFIG_DIR / "wad",
}


# Colors
class Colors:
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    BLUE = "\033[0;34m"
    RED = "\033[0;31m"
    NC = "\033[0m"


def log(msg):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")


def warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")


def ensure_directories():
    for dir_path in DIRS.values():
        dir_path.mkdir(parents=True, exist_ok=True)


def get_files(patterns, dir_path):
    if isinstance(patterns, str):
        patterns = [patterns]

    all_files = list(dir_path.glob("*"))
    matched_files = []

    for pattern in patterns:
        # Case-insensitive matching using both upper and lower case patterns
        matched_files.extend(
            f
            for f in all_files
            if fnmatch.fnmatch(f.name.lower(), pattern.lower())
            or fnmatch.fnmatch(f.name.upper(), pattern.upper())
        )

    return sorted({f.name for f in matched_files})


def get_validated_choice(prompt, max_choice, allow_zero=False):
    """Shared input validation for both single and multi selection"""
    while True:
        choice = input(prompt)
        if allow_zero and choice == "0":
            return 0
        try:
            choice_num = int(choice)
            if 1 <= choice_num <= max_choice:
                return choice_num
            error(f"Please enter a number between 1 and {max_choice}")
        except ValueError:
            error("Please enter a valid number")


def select_one(files, prompt):
    print(f"\n{Colors.BLUE}=== {prompt} ==={Colors.NC}")
    for i, f in enumerate(files, 1):
        print(f"{i}) {f}")

    choice = get_validated_choice(f"Enter your choice (1-{len(files)}): ", len(files))
    return files[choice - 1]


def select_multi(files, prompt, require_one=False):
    print(f"\n{Colors.BLUE}=== {prompt} ==={Colors.NC}")
    for i, f in enumerate(files, 1):
        print(f"{i}) {f}")
    print("0) Done selecting")

    selected = []
    while True:
        choice = get_validated_choice(
            "Enter choice (0 to finish): ", len(files), allow_zero=True
        )
        if choice == 0:
            if require_one and len(selected) == 0:
                error("You must select at least 1 file.")
                continue
            break

        selected_file = files[choice - 1]
        if selected_file in selected:
            warn(f"Already selected: {selected_file}")
        else:
            selected.append(selected_file)
            log(f"Selected: {selected_file}")

    return selected


def main():
    # Check if gzdoom is available
    if not subprocess.run(["which", "gzdoom"], capture_output=True).returncode == 0:
        error("gzdoom not found in PATH. Please install GZDoom first.")
        return 1

    ensure_directories()

    # Get files
    iwads = get_files("*.wad", DIRS["iwad"])
    pk3s = get_files(["*.pk3", "*.zip"], DIRS["pk3"])
    wads = get_files("*.wad", DIRS["wad"])

    # Check requirements
    if not iwads:
        error(f"No IWAD files found in {DIRS['iwad']}")
        error(
            "Please place at least one IWAD file (e.g., DOOM.WAD, DOOM2.WAD) in the iwad directory."
        )
        return 1

    print(f"{Colors.GREEN}=== GZDoom Launcher ==={Colors.NC}")
    print(f"Found {len(iwads)} IWAD(s), {len(pk3s)} PK3(s), {len(wads)} WAD(s)")

    # Select files
    selected_iwad = select_one(iwads, "Select IWAD (choose 1)")

    selected_pk3s = []
    if pk3s:
        selected_pk3s = select_multi(
            pk3s, "Select PK3 files (choose multiple, or 0 to skip)"
        )
    else:
        print(
            f"{Colors.YELLOW}No PK3 files found in {DIRS['pk3']} - skipping PK3 selection{Colors.NC}"
        )

    selected_wads = []
    if wads:
        selected_wads = select_multi(
            wads, "Select WAD files (choose multiple, or 0 to skip)"
        )
    else:
        print(
            f"{Colors.YELLOW}No WAD files found in {DIRS['wad']} - skipping WAD selection{Colors.NC}"
        )

    # Show summary
    print(f"\n{Colors.GREEN}=== Launch Configuration ==={Colors.NC}")
    print(f"IWAD: {selected_iwad}")
    if selected_pk3s:
        print(f"PK3s: {', '.join(selected_pk3s)}")
    if selected_wads:
        print(f"WADs: {', '.join(selected_wads)}")

    # Confirm launch
    confirm = input("\nLaunch GZDoom with this configuration? (Y/n): ").lower()
    if confirm == "n":
        log("Launch cancelled.")
        return 0

    # Build command
    cmd = ["gzdoom", "-iwad", str(DIRS["iwad"] / selected_iwad)]

    for pk3 in selected_pk3s:
        cmd.extend(["-file", str(DIRS["pk3"] / pk3)])

    for wad in selected_wads:
        cmd.extend(["-file", str(DIRS["wad"] / wad)])

    # Launch with version compatibility
    log(f"Launching: {' '.join(cmd)}")

    # Set environment variable to make GZDoom think it's version 4.11
    env = {**os.environ, "GZDOOM_VERSION": "4.11.0"}

    # Use subprocess.run for better control and error handling
    result = subprocess.run(cmd, env=env)
    return result.returncode


if __name__ == "__main__":
    exit(main())
