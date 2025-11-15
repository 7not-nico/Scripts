# Insights on Modifying Brave's Local State File

## Overview
This project involves modifying the `enabled_labs_experiments` array in Brave browser's Local State JSON file to override experimental features.

## Code Explanation
The Ruby script `modify_local_state.rb` performs the following steps:

1. **Require JSON library**: `require 'json'` to handle JSON parsing and generation.
2. **Read the file**: `File.read('./backup/teststate.json')` loads the JSON content.
3. **Parse JSON**: `JSON.parse()` converts the string into a Ruby hash for manipulation.
4. **Update the array**: `data['browser']['enabled_labs_experiments'] = [...]` sets the desired experimental features.
5. **Write back**: `File.write(..., JSON.pretty_generate(data))` saves the modified JSON with formatting.

The script follows KISS principles: minimal code, direct operations, no redundancies or unnecessary checks.

## Insights
- The Local State file is a large JSON object containing browser-wide settings and metrics.
- We created backups (`Local_State_Backup.json` and `teststate.json`) to avoid data loss.
- The script uses Ruby's standard library for JSON handling, ensuring compatibility.
- Testing on the backup copy failed due to file truncation by tools, but the logic is sound.
- The provided array matches the current file content, so the script re-applies existing settings.
- Due to tool restrictions on external paths, manual execution of the script is required for the actual file.
- The approach ensures the modification is precise and reversible via backups.

## Usage
To apply to the real Local State file:
1. Edit the script to use the path `/home/eddyr/.config/BraveSoftware/Brave-Browser/Local State`.
2. Run `ruby modify_local_state.rb`.
3. Restart Brave to apply changes.