# ──────────────────────────────────────────────────────────
# GuestList - Development Dependencies
# Install with: brew bundle
# ──────────────────────────────────────────────────────────

# Swift toolchain (if not on macOS)
brew "swift" if OS.linux?

# Version control
brew "git"                # Distributed version control system
brew "gh"                 # GitHub CLI tool

# File watching for hot reload during development
brew "watchexec"

# Container runtime
cask "orbstack" if OS.macOS?
brew "docker" if OS.linux?       # Standard Docker for Linux
