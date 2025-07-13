# Nushell Scripts Organization

This directory contains all Nushell scripts for the Yazelix project, organized by functionality.

## Directory Structure

### `core/` - Core Yazelix Functionality
Essential scripts that provide the main Yazelix functionality:
- `start_yazelix.nu` - Main launcher that starts Zellij with Yazelix layout
- `launch_yazelix.nu` - Terminal launcher that opens your preferred terminal emulator
- `yazelix.nu` - Command suite with subcommands (`yzx help`, `yzx versions`, etc.)

### `integrations/` - Tool Integration Scripts
Scripts that handle integration between Yazi, Zellij, and Helix:
- `yazi.nu` - Yazi integration utilities (file opening, reveal in sidebar)
- `zellij.nu` - Zellij integration utilities (pane management, Helix detection)
- `helix.nu` - Helix integration utilities (binary detection, testing)
- `open_file.nu` - Wrapper script called by Yazi to open files in Helix
- `reveal_in_yazi.nu` - Wrapper script for revealing files in Yazi sidebar

### `setup/` - Setup and Configuration Scripts
Scripts for initial setup and configuration:
- `environment.nu` - Main environment setup script
- `config.nu` - Configuration management
- `generate_zellij_config.nu` - Dynamic Zellij configuration generation
- `initializers.nu` - Initializer script generation

### `utils/` - Utility Functions
Reusable utility functions and helpers:
- `constants.nu` - Project constants and configuration
- `version_info.nu` - Version information utilities
- `config_manager.nu` - Configuration management utilities
- `helix_mode.nu` - Helix mode detection and setup
- `common.nu` - Common utility functions
- `logging.nu` - Logging utilities

### `dev/` - Development Tools
Scripts for development, testing, and maintenance:
- `record_demo.nu` - VHS demo recording with font support
- `test_fonts.nu` - Font testing for VHS recordings

## Usage

### Core Commands
```bash
# Start Yazelix
nu ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu

# Launch terminal
nu ~/.config/yazelix/nushell/scripts/core/launch_yazelix.nu

# Use command suite
nu ~/.config/yazelix/nushell/scripts/core/yazelix.nu help
```

### Development Tools
```bash
# Record demos
nu ~/.config/yazelix/nushell/scripts/dev/record_demo.nu quick

# Test fonts
nu ~/.config/yazelix/nushell/scripts/dev/test_fonts.nu
```

## File Naming Convention
All files use underscores (e.g., `start_yazelix.nu`, `open_file.nu`) - never hyphens. 