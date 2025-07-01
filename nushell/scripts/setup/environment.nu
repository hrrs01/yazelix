#!/usr/bin/env nu
# Main Yazelix environment setup script
# Called from flake.nix shellHook to reduce complexity

def main [
    yazelix_dir: string
    include_optional: bool
    build_helix_from_source: bool
    default_shell: string
    debug_mode: bool
    extra_shells_str: string
    skip_welcome_screen: bool
    helix_mode: string
] {
    # Parse extra shells from comma-separated string
    let extra_shells = if ($extra_shells_str | is-empty) or ($extra_shells_str == "NONE") {
        []
    } else {
        $extra_shells_str | split row "," | where $it != ""
    }

    # Determine which shells to configure (always nu/bash, plus default_shell and extra_shells)
    let shells_to_configure = (["nu", "bash"] ++ [$default_shell] ++ $extra_shells) | uniq

    # Setup logging
    let log_dir = $"($yazelix_dir)/logs"
    mkdir $log_dir

    # Auto-trim old logs (keep 10 most recent)
    let old_logs = try {
        ls $"($log_dir)/shellhook_*.log"
        | sort-by modified -r
        | skip 10
        | get name
    } catch { [] }

    if not ($old_logs | is-empty) {
        rm ...$old_logs
    }

    let log_file = $"($log_dir)/shellhook_(date now | format date '%Y%m%d_%H%M%S').log"

    print $"🚀 Yazelix Environment Setup Started"
    print $"📝 Logging to: ($log_file)"

    # Generate shell initializers for configured shells only
    print "🔧 Generating shell initializers..."
    nu $"($yazelix_dir)/nushell/scripts/setup/initializers.nu" $yazelix_dir $include_optional ($shells_to_configure | str join ",")

    # Clean up Steel artifacts if switching away from Steel mode
    if $helix_mode != "steel" {
        cleanup_steel_artifacts $yazelix_dir
    }

    # Setup Helix based on mode
    if $helix_mode == "source" {
        print "🔧 Using Helix flake from repository (always updated)..."
        # No setup needed - flake.nix handles this automatically
    } else if $helix_mode == "release" {
        print "✅ Using latest Helix release from nixpkgs (no custom build needed)"

    } else if $helix_mode == "steel" {
        print "🔧 Setting up steel plugin system Helix..."
        setup_steel_helix $yazelix_dir
    } else {
        print "✅ Using default nixpkgs Helix (no custom build needed)"
    }

    # Setup shell configurations (always setup bash/nu, conditionally setup fish/zsh)
    setup_bash_config $yazelix_dir
    setup_nushell_config $yazelix_dir

    if ("fish" in $shells_to_configure) {
        setup_fish_config $yazelix_dir
    }

    if ("zsh" in $shells_to_configure) {
        setup_zsh_config $yazelix_dir
    }

    # Setup editor
    setup_helix_config ($helix_mode != "default") $yazelix_dir

    # Set permissions
    chmod +x $"($yazelix_dir)/bash/launch-yazelix.sh"
    chmod +x $"($yazelix_dir)/bash/start-yazelix.sh"

    print "✅ Yazelix environment setup complete!"

    # Prepare welcome message
    let helix_info = if $helix_mode == "source" {
        $"   🔄 Using Helix flake from repository for latest features"
    } else if $helix_mode == "release" {
        "   📦 Using latest Helix release from nixpkgs (fast setup)"

    } else if $helix_mode == "steel" {
        "   ⚡ Steel plugin system enabled with scheme scripting (interpreter + LSP auto-installed)"
    } else {
        $"   📝 Using stable nixpkgs Helix"
    }

    let welcome_message = [
        "",
        "🎉 Welcome to Yazelix v7!",
        "   Your integrated terminal environment with Yazi + Zellij + Helix",
        "   ✨ Now with Nix auto-setup, lazygit, Starship, and markdown-oxide",
        $helix_info,
        "   🔧 All dependencies installed, shell configs updated, tools ready",
        "",
        "   Quick tips: Use 'alt hjkl' to navigate, 'Enter' in Yazi to open files",
        ""
    ] | where $it != ""

    # Show welcome screen or log it
    if $skip_welcome_screen {
        # Log welcome info instead of displaying it
        let welcome_log_file = $"($log_dir)/welcome_(date now | format date '%Y%m%d_%H%M%S').log"
        $welcome_message | str join "\n" | save $welcome_log_file
        print $"💡 Welcome screen skipped. Welcome info logged to: ($welcome_log_file)"
    } else {
        # Display welcome screen with pause
        for $line in $welcome_message {
            print $line
        }
        input "   Press Enter to launch Zellij and start your session... "
    }
}

def setup_bash_config [yazelix_dir: string] {
    let bash_config = $"($yazelix_dir)/bash/yazelix_bash_config.sh"
    let bashrc = $"($env.HOME)/.bashrc"
    let comment = "# Source Yazelix Bash configuration (added by Yazelix)"
    let source_line = $"source \"($bash_config)\""

    if not ($bash_config | path exists) {
        print $"⚠️  Bash config not found: ($bash_config)"
        return
    }

    touch $bashrc
    let bashrc_content = (open $bashrc)

    if not ($bashrc_content | str contains $comment) {
        print $"🐚 Adding Yazelix Bash config to ($bashrc)"
        $"\n($comment)\n($source_line)" | save --append $bashrc
    } else {
        print $"✅ Bash config already sourced"
    }
}

def setup_nushell_config [yazelix_dir: string] {
    let nushell_config = $"($env.HOME)/.config/nushell/config.nu"
    let yazelix_config = $"($yazelix_dir)/nushell/config/config.nu"
    let comment = "# Source Yazelix Nushell configuration (added by Yazelix)"
    let source_line = $"source \"($yazelix_config)\""

    mkdir ($nushell_config | path dirname)

    if not ($nushell_config | path exists) {
        print $"📝 Creating new Nushell config: ($nushell_config)"
        "# Nushell user configuration (created by Yazelix setup)" | save $nushell_config
    }

    let config_content = (open $nushell_config)

    if not ($config_content | str contains $comment) {
        print $"🐚 Adding Yazelix Nushell config to ($nushell_config)"
        $"\n($comment)\n($source_line)" | save --append $nushell_config
    } else {
        print $"✅ Nushell config already sourced"
    }
}

def setup_fish_config [yazelix_dir: string] {
    let fish_config = $"($env.HOME)/.config/fish/config.fish"
    let yazelix_config = $"($yazelix_dir)/fish/yazelix_fish_config.fish"
    let comment = "# Source Yazelix Fish configuration (added by Yazelix)"
    let source_line = $"source \"($yazelix_config)\""

    if not ($yazelix_config | path exists) {
        print $"⚠️  Fish config not found, skipping Fish setup"
        return
    }

    mkdir ($fish_config | path dirname)
    touch $fish_config
    let config_content = (open $fish_config)

    if not ($config_content | str contains $comment) {
        print $"🐚 Adding Yazelix Fish config to ($fish_config)"
        $"\n($comment)\n($source_line)" | save --append $fish_config
    } else {
        print $"✅ Fish config already sourced"
    }
}

def setup_zsh_config [yazelix_dir: string] {
    let zsh_config = $"($env.HOME)/.zshrc"
    let yazelix_config = $"($yazelix_dir)/zsh/yazelix_zsh_config.zsh"
    let comment = "# Source Yazelix Zsh configuration (added by Yazelix)"
    let source_line = $"source \"($yazelix_config)\""

    if not ($yazelix_config | path exists) {
        print $"⚠️  Zsh config not found, skipping Zsh setup"
        return
    }

    mkdir ($zsh_config | path dirname)
    touch $zsh_config
    let config_content = (open $zsh_config)

    if not ($config_content | str contains $comment) {
        print $"🐚 Adding Yazelix Zsh config to ($zsh_config)"
        $"\n($comment)\n($source_line)" | save --append $zsh_config
    } else {
        print $"✅ Zsh config already sourced"
    }
}

def setup_helix_config [use_custom_helix: bool = false, yazelix_dir: string = ""] {
    let editor = if $use_custom_helix and ($yazelix_dir != "") {
        let custom_hx = $"($yazelix_dir)/helix_custom/target/release/hx"
        if ($custom_hx | path exists) {
            print $"📝 Using custom-built Helix: ($custom_hx)"
            $custom_hx
        } else {
            print $"⚠️  Custom Helix not found, falling back to system hx"
            "hx"
        }
    } else {
        "hx"
    }

    print $"📝 Setting EDITOR to: ($editor)"
    $env.EDITOR = $editor

    # Create hx alias for custom build if available
    if $use_custom_helix and ($yazelix_dir != "") {
        let custom_hx = $"($yazelix_dir)/helix_custom/target/release/hx"
        if ($custom_hx | path exists) {
            # This will be picked up by shell configs
            $env.YAZELIX_CUSTOM_HELIX = $custom_hx
        }
    }
}



def setup_steel_helix [
    yazelix_dir: string
] {
    let helix_custom_dir = $"($yazelix_dir)/helix_custom"

    # Create helix-custom directory if it doesn't exist
    if not ($helix_custom_dir | path exists) {
        print $"📂 Creating steel Helix directory: ($helix_custom_dir)"
        mkdir $helix_custom_dir

        # Clone steel branch directly (much simpler than merging)
        cd $yazelix_dir
        print "🔄 Cloning steel plugin system branch..."
        try {
            git clone -b steel-event-system https://github.com/mattwparas/helix.git helix_custom
            print "✅ Successfully cloned steel plugin system branch"
        } catch {
            print "⚠️  Failed to clone steel branch, falling back to master"
            git clone https://github.com/helix-editor/helix.git helix_custom
        }
    } else {
        print $"📂 Steel Helix directory exists: ($helix_custom_dir)"
        cd $helix_custom_dir

        # Check if we're on the right branch
        let current_branch = try { git branch --show-current } catch { "unknown" }
        if $current_branch != "steel-event-system" {
            print "🔄 Switching to steel-event-system branch..."
            try {
                git remote add steel-origin https://github.com/mattwparas/helix.git
            } catch {
                # Remote might already exist
            }
            try {
                git fetch steel-origin steel-event-system
                git checkout -b steel-event-system steel-origin/steel-event-system
                print "✅ Switched to steel plugin system branch"
            } catch {
                print "⚠️  Could not switch to steel branch"
            }
        }
    }

    # Build steel Helix
    cd $helix_custom_dir
    print "🔨 Building steel plugin system Helix (this may take a few minutes)..."
    try {
        cargo build --release
        print "✅ Steel Helix built successfully!"
        print $"🎯 Steel-enabled Helix binary available at: ($helix_custom_dir)/target/release/hx"

        # Create symlink for user helix config to be accessible
        let user_helix_config = $"($env.HOME)/.config/helix"
        let user_helix_runtime = $"($user_helix_config)/runtime"
        let steel_runtime = $"($helix_custom_dir)/runtime"

        mkdir $user_helix_config

        # Remove existing runtime link/dir if it exists
        if ($user_helix_runtime | path exists) {
            rm -rf $user_helix_runtime
        }

        # Create symlink from user config to steel runtime
        try {
            ln -sf $steel_runtime $user_helix_runtime
            print $"🔗 Created runtime symlink: ($user_helix_runtime) -> ($steel_runtime)"
        } catch {
            print $"⚠️  Could not create runtime symlink, you may need to set HELIX_RUNTIME manually"
        }

        # Setup additional steel tools (language server, forge, etc.)
        print "🔧 Setting up additional steel tools..."
        try {
            cargo xtask steel
            print "✅ Additional steel tools installed successfully!"
            print "   • steel-language-server - Steel LSP server"
            print "   • forge - Steel package manager"
            print "   • cargo-steel-lib - Steel library manager"
        } catch {|err|
            print $"⚠️  Failed to install additional steel tools: ($err.msg)"
            print "   You can install them manually with: cargo xtask steel"
        }

        # Setup default Steel example plugin
        print "🔧 Setting up default Steel example plugin..."
        setup_default_steel_plugin $yazelix_dir
    } catch {|build_err|
        print $"⚠️  Failed to build steel Helix: ($build_err.msg)"
        print "   You can build manually with: cargo build --release"
        print $"   Navigate to: ($helix_custom_dir)"
    }
}

def setup_default_steel_plugin [yazelix_dir: string] {
    let helix_config_dir = $"($env.HOME)/.config/helix"
    let helix_scm = $"($helix_config_dir)/helix.scm"
    let init_scm = $"($helix_config_dir)/init.scm"

    # Ensure helix config directory exists
    mkdir $helix_config_dir

    # Create default helix.scm plugin if it doesn't exist or is empty
    if not ($helix_scm | path exists) or (($helix_scm | path exists) and ((open $helix_scm | str trim) == "")) {
        print $"📝 Creating default Steel plugin: ($helix_scm)"
        let plugin_content = [
            ";; Yazelix Default Steel Plugin"
            ";; Ultra-simplified plugin with clean output formatting"
            ""
            ";; Simple greeting function with clean output"
            "(define (hello-steel)"
            "  (displayln \"\")"
            "  (displayln \"=== Steel Plugin Test ===\")"
            "  (displayln \"Steel Plugin System is Working!\")"
            "  (displayln \"========================\")"
            "  (displayln \"\"))"
            ""
            ";; Export the function so it can be called as a typed command"
            "(provide hello-steel)"
        ]
        $plugin_content | str join "\n" | save $helix_scm
    } else {
        print $"✅ Steel plugin already exists: ($helix_scm)"
    }

    # Create default init.scm if it doesn't exist or is empty
    if not ($init_scm | path exists) or (($init_scm | path exists) and ((open $init_scm | str trim) == "")) {
        print $"📝 Creating default Steel initialization: ($init_scm)"
        let init_content = [
            ";; Yazelix Steel Plugin System Initialization"
            ";; Clean startup with better formatting"
            ""
            "(displayln \"\")"
            "(displayln \"=========================================\")"
            "(displayln \"🔧 Steel Plugin System Initialized!\")"
            "(displayln \"=========================================\")"
            "(displayln \"\")"
            "(displayln \"Yazelix Ultra-Basic Steel Plugin Loaded\")"
            "(displayln \"\")"
            "(displayln \"Available commands:\")"
            "(displayln \"  :hello-steel    - Test greeting\")"
            "(displayln \"\")"
            "(displayln \"💡 Tip: Type ':' followed by command name!\")"
            "(displayln \"📖 Clean, safe Steel function\")"
            "(displayln \"\")"
            "(displayln \"=========================================\")"
            "(displayln \"Steel initialization complete!\")"
            "(displayln \"=========================================\")"
            "(displayln \"\")"
        ]
        $init_content | str join "\n" | save $init_scm
    } else {
        print $"✅ Steel initialization already exists: ($init_scm)"
    }

    print $"✅ Default Steel plugin setup complete!"
    print $"   Plugin file: ($helix_scm)"
    print $"   Init file: ($init_scm)"
}

def cleanup_steel_artifacts [yazelix_dir: string] {
    let helix_config_dir = $"($env.HOME)/.config/helix"
    let helix_scm = $"($helix_config_dir)/helix.scm"
    let init_scm = $"($helix_config_dir)/init.scm"
    let helix_custom_dir = $"($yazelix_dir)/helix_custom"

    # Check if Steel artifacts exist
    let has_steel_config = ($helix_scm | path exists) or ($init_scm | path exists)
    let has_steel_build = ($helix_custom_dir | path exists) and (try {
        cd $helix_custom_dir
        git branch --show-current
    } catch { "unknown" } | str contains "steel")

    if $has_steel_config or $has_steel_build {
        print "🧹 Detected Steel artifacts from previous Steel mode setup"
        print "   Cleaning up Steel configuration files and build artifacts..."

        # Remove ONLY Steel configuration files (.scm files)
        if ($helix_scm | path exists) {
            rm $helix_scm
            print $"   ✅ Removed Steel plugin: ($helix_scm)"
        }

        if ($init_scm | path exists) {
            rm $init_scm
            print $"   ✅ Removed Steel initialization: ($init_scm)"
        }

        # Clean Steel build artifacts if switching to non-Steel mode
        if $has_steel_build {
            print "   🔄 Steel build detected - cleaning for fresh build..."
            if ($helix_custom_dir | path exists) {
                # Use system rm to avoid "cannot remove any parent directory" error
                try {
                    ^rm -rf $helix_custom_dir
                    print $"   ✅ Removed Steel build directory: ($helix_custom_dir)"
                } catch {
                    print $"   ⚠️  Could not remove Steel build directory: ($helix_custom_dir)"
                    print "   💡 You may need to manually remove it or restart your terminal"
                }
            }
        }

        print "   🎯 Steel artifacts cleaned up successfully!"
        print "   💡 Your Helix will now use the configured mode without Steel plugins"
        print "   🔒 Preserved all other Helix configuration files"
    }
}