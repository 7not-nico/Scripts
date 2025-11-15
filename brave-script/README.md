# Brave Browser Local State Modifier

A Ruby script to modify Brave browser's Local State file to enable experimental features for improved performance.

## Overview

This script enables various experimental features in Brave browser by modifying the `enabled_labs_experiments` array in the Local State JSON file. Features include Vulkan rendering, GPU rasterization, and other performance optimizations.

## Script

- `modify_local_state.rb`: Modifies Local State to enable experimental features

## Usage

```bash
ruby modify_local_state.rb
```

After running, restart Brave browser to apply the changes.

## Enabled Features

The script enables the following experimental features:

- `default-angle-vulkan@1`: Use Vulkan with ANGLE
- `enable-gpu-rasterization@1`: Enable GPU rasterization
- `enable-zero-copy@1`: Enable zero-copy uploads
- `ignore-gpu-blocklist`: Ignore GPU blocklist
- `pdf-use-skia-renderer@1`: Use Skia for PDF rendering
- `skia-graphite@1`: Enable Skia Graphite
- `vulkan-from-angle@1`: Enable Vulkan from ANGLE

## Safety

- The script creates a backup of the original Local State file
- Uses direct string manipulation with regex for precise modifications
- No external dependencies required

## Notes

- Requires Brave browser to be installed
- Modifies `~/.config/BraveSoftware/Brave-Browser/Local State`
- Restart browser after modification to apply changes
- Backup files are stored in the `backup/` directory</content>
<parameter name="filePath">/home/eddyr/_repo/Scripts/brave-script/README.md