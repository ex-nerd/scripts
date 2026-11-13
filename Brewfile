#!/usr/bin/env brew bundle upgrade --file
# Yes, that shebang is magic.  Just execute this file via ./Brewfile to make it work.
#
# Don"t forget to set HOMEBREW_CASK_OPTS="--no-quarantine"

# Lots of helpful setup info here: https://thebiglog.com/posts/macos-migrations-with-brewfile

###############################################################################
# Taps and Setup

# No taps are currently used.

# For mac app store stuff (including later in this file)
brew "mas"

###############################################################################
# Fonts

# for old versions of the seagl program
# cask "font-dosis"

# No nerd font available for the plain MDI font
cask "font-material-icons"

# Nerd fonts
cask "font-hack-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-sauce-code-pro-nerd-font"
cask "font-source-code-pro"
cask "font-monoid-nerd-font"
cask "font-fira-code-nerd-font"


###############################################################################
# Core shell environment

brew "bash"
brew "bash-completion"

brew "starship"

brew "coreutils"
brew "gnu-sed"  # --with-default-names
brew "findutils"  # --with-default-names
brew "grep"  # --with-default-names
brew "rsync"
brew "wget"
brew "ssh-copy-id"

brew "pwgen"
brew "rename"
brew "dos2unix"

brew "bat"
brew "bat-extras"
brew "lsd"
brew "ripgrep"
brew "btop"

###############################################################################
# Coding

# Run LLMs with MLX using uv tool, not homebrew:
# uv tool install --with torch rapid-mlx --force
# uv tool install --with jinja2 mlx-vlm --force

# Version Control
brew "subversion"
brew "git"
brew "git-lfs"
brew "git-delta"
brew "gh"   # official github client: https://cli.github.com/
# brew "hub"  # "unofficial" github client, mimics git: https://hub.github.com/

# IDEs and editors
cask "visual-studio-code"
cask "sublime-text"
brew "nano"

# Developer virtual environments
brew "direnv"
brew "mise"
brew "uv"
brew "pipx"

# Developer tools
brew "ansible"
brew "black"
brew "colordiff"
brew "hugo"
brew "jq"
brew "prettier"
brew "qrencode"
brew "shellcheck"
brew "sqlite"

###############################################################################
# Audio, Video, and other media

# cask "handbrake"
# cask "makemkv"
brew "ffmpeg"
cask "vlc"
cask "plex"
brew "imagemagick"
brew "exiftool"
brew "imageoptim-cli"
brew "pngquant"

brew "libdvdcss"
brew "mp4v2"
brew "gpac" #formerly known as mp4box

# for photorec, memory card un-deleter
# brew "testdisk"

###############################################################################
# Mac App Store and Other Desktop Apps

# Interior design application
cask "sweet-home3d"

# Menu bar app for USB-C cable diagnostics
# I prefer to use it from linux
#cask "whatcable"

# Menu bar calendar
cask "itsycal"

# System cleaner, optimiser, and malware scanner
cask "mac-sai"

# Voice and text chat software
cask "discord"

# Tor…
cask "tor-browser"

# Free cross-platform office suite, fresh version
# cask "libreoffice"

# Browser plugins
# mas "1Password for Safari", id: 1569813296
mas "uBlock Origin Lite", id: 6745342698
mas "Privacy Badger", id: 0
mas "Tab for a Cause", id: 1579749108

mas "GeoTag", id: 1465180184
mas "PCalc", id: 403504866

mas "Gemini 2", id: 1090488118 # duplicate finder
mas "OpenIn", id: 1643649331
mas "RenameNinja", id: 6745643774
mas "ShellHistory", id: 1564015476
mas "The Unarchiver", id: 425424353

# Windows Remote Desktop
# mas "Windows App", id: 1295203466

# Developer stuff I want to manage manually
# mas "Blackmagic Disk Speed Test", id: 425264550
# mas "LightBlue", id: 557428110 # bluetooth scanner
# mas "Discovery", id: 1381004916 # Bonjour Browser
# mas "TestFlight", id: 899247664
# mas "Xcode", id: 497799835

# 3D and CAD
cask "openscad@snapshot"
# cask "meshlab"
# cask "meshmixer"

# And OpenSCAD
# xattr -cr /Applications/OpenSCAD.app/

###############################################################################
# Quicklook Plugins (and related apps)

# This includes an app and an installer-package ql plugin
# https://www.mothersruin.com/software/SuspiciousPackage/
cask "suspicious-package"

# Great list of QL plugins via https://github.com/sindresorhus/quick-look-plugins
# See also https://www.quicklookplugins.com/
cask "provisionql"
cask "qlmarkdown"
cask "quicklook-video"
cask "syntax-highlight"

# Run these to silence warnings about quicklook plugins
# xattr -cr ~/Library/QuickLook/*

