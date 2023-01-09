#!/usr/bin/env brew bundle install
# Yes, that shebang is magic.  Just execute this file via ./Brewfile to make it work.

# Lots of helpful setup info here: https://openfolder.sh/macos-migrations-with-brewfile

tap 'homebrew/cask'
tap 'homebrew/cask-versions'
tap 'mas-cli/tap'
tap 'homebrew/cask-fonts'

# For mac app store stuff (including later in this file)
brew 'mas'

# Core stuff
brew 'coreutils'
brew 'gnu-sed'  # --with-default-names
brew 'findutils'  # --with-default-names
brew 'grep'  # --with-default-names
brew 'progress'  # https://github.com/Xfennec/progress
brew 'direnv'
brew 'pv'
#brew 'tee'  # No brew for this (it's built-in)
brew 'pwgen'

brew 'git'
brew 'git-lfs'
brew 'hub'  # "unofficial" github client, mimics git: https://hub.github.com/
brew 'gh'   # official github client: https://cli.github.com/
brew 'bash'
brew 'bash-completion'
brew 'wget'
brew 'colordiff'

brew 'pyenv'
brew 'zlib'  # for pyenv until BigSur issues are fixed
brew 'bzip2'  # for pyenv until BigSur issues are fixed
# FIXME: figure out how to run this via brew?
# $(brew --prefix)/bin/pip install virtualenvwrapper ipython

brew 'imagemagick'

brew 'libdvdcss'
brew 'mp4v2'
brew 'gpac'

brew 'ssh-copy-id'
brew 'rename'

brew 'html-xml-utils'

brew 'hugo'
brew 'tree'

# 3d printer stuff
cask 'bossa'

# Better than Apple's built-in one
brew 'nano'

# for json parsing via bash
brew 'jq'

# for photorec, memory card un-deleter
brew 'testdisk'

# Install Mac App Store apps first, since we prefer these over casks

mas 'Better Rename 9', id: 414209656
mas 'Deliveries', id: 924726344
mas 'Fantastical', id: 975937182
mas 'Gemini 2', id: 1090488118
mas 'PCalc', id: 403504866
mas 'Pixelmator Pro', id: 1289583905
mas 'Slack', id: 803453959
mas 'SSH Tunnel Manager', id: 424470626
mas 'Textual 7', id: 1262957439
mas 'The Unarchiver', id: 425424353
# mas 'Xcode', id: 497799835 # Don't really need xcode everywhere

# mas 'Final Cut Pro', id: 424389933
# mas 'iMovie', id: 408981434
# mas 'Motion', id: 434290957
# mas 'Compressor', id: 424390742
# mas 'RBdigital', id: 491365225
# mas 'Keynote', id: 409183694
# mas 'Numbers', id: 409203825
# mas 'Pages', id: 409201541
# mas 'Wimoweh', id: 610341008
# mas 'Moom', id: 419330170
# mas 'Witch', id: 412485838
# mas 'CleanMyDrive 2', id: 523620159
# mas 'Sugarmate Glance', id: 1207352056

# Fonts

cask 'font-hack'
cask 'font-fira-code'
cask 'font-monoid'
cask 'font-source-code-pro'
# for seagl program
cask 'font-dosis'

# List of all cask apps (truncated by github display):
# https://github.com/caskroom/homebrew-cask/tree/master/Casks
# Search via: `brew search --casks`

cask 'imageoptim'
cask 'imagealpha'
cask 'handbrake'
cask 'makemkv'
cask 'vlc'
cask 'plex'
cask 'steam'

cask 'tor-browser'

#cask '1password-cli'

# cask 'bettertouchtool' # prefer to manage manually
# cask 'iterm2-beta' # prefer to manage manually

# cask 'prusaslicer' # prefer to install manually for betas
cask 'openscad-snapshot'
cask 'meshlab'
cask 'meshmixer'

cask 'discord'
# cask 'openemu' # exists but I don't want it at the moment

cask 'xquartz'
cask 'inkscape'
cask 'libreoffice'

cask 'visual-studio-code'
cask 'sublime-text'

# This includes the betterzipql plugin, too
# The app itself is shareware, and Unarchiver is free/easy but no QL plugin
#cask 'betterzip'

# This includes an app and an installer-package ql plugin
# https://www.mothersruin.com/software/SuspiciousPackage/
cask 'suspicious-package'

# Great list of QL plugins via https://github.com/sindresorhus/quick-look-plugins
# See also https://www.quicklookplugins.com/
cask 'ProvisionQL'
cask 'qlcolorcode'
cask 'qlstephen'
cask 'qlmarkdown'
cask 'quicklook-json'
cask 'qlprettypatch'
cask 'quicklook-csv'
cask 'qlimagesize'
cask 'webpquicklook'
cask 'quicklookase'
cask 'qlvideo'
#  sad..  no longer available: cert-quicklook

# Run these to silence warnings about quicklook plugins
# xattr -cr ~/Library/QuickLook/QLColorCode.qlgenerator/
# xattr -cr ~/Library/QuickLook/QLStephen.qlgenerator/
# xattr -cr ~/Library/QuickLook/QLMarkdown.qlgenerator/
# And OpenSCAD
# xattr -cr /Applications/OpenSCAD.app/

# for https://github.com/alex20465/deskbluez
# commented out because deskbluez doesn't run
# brew glib
# brew dlib
