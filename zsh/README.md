# Zsh Configuration for Yazelix

This directory contains Zsh-specific configuration files for Yazelix.

## Files

- `yazelix_zsh_config.zsh` - Main Zsh configuration that sources tool initializers and sets up aliases
- `initializers/` - Directory containing auto-generated initializer scripts for various tools

## How it works

1. When Yazelix starts, it automatically generates initializer scripts for tools like:
   - Starship (prompt)
   - Zoxide (smart directory navigation)
   - Mise (tool version manager) - optional
   - Carapace (completions) - optional

2. The main configuration file (`yazelix_zsh_config.zsh`) sources these initializers and provides:
   - `yazelix` and `yzx` aliases for launching Yazelix
   - `lg` alias for lazygit
   - Integration with Yazelix environment

3. Your `~/.zshrc` is automatically updated to source the Yazelix configuration when you first run Yazelix

## Usage

To use zsh as your default shell in Yazelix, update your `~/.config/yazelix/yazelix.nix`:

```nix
{
  default_shell = "zsh";
  # ... other configuration
}
```

## Notes

- All tools (starship, zoxide, mise, etc.) are available in your PATH when using zsh
- The configuration is designed to not interfere with your existing zsh setup
- Tool initializers are regenerated each time you start the Yazelix environment 