#!/bin/zsh
# Prompt setup and enhancement. This is meant for my starship config
# but includes some fallbacks for systems that might not have starship.
#

autoload -Uz add-zsh-hook

###############################################################################
# Set a backup prompt if we don't have starship installed
#

if (( ! $+commands[starship] )); then
  # Declare temporary formatting variables to keep them out of the final environment
  local c_red c_lred c_green c_blue c_cyan c_dgray c_reset

  # 2. Set ANSI colors safely (respecting NO_COLOR standards)
  if [[ -z "${NO_COLOR:-}" ]]; then
    c_red="\[\e[31m\]"
    c_lred="\[\e[91m\]"
    c_green="\[\e[32m\]"
    c_blue="\[\e[34m\]"
    c_cyan="\[\e[36m\]"
    c_dgray="\[\e[90m\]"
    c_reset="\[\e[0m\]"
  else
    c_red="" c_lred="" c_green="" c_blue="" c_cyan="" c_dgray="" c_reset=""
  fi

  # 3. Apply prompt based on privileges (Red for Root, Blue/Cyan for standard users)
  if [[ $EUID == 0 ]]; then
    PS1="${c_red}\u${c_lred}@\h${c_reset}: ${c_green}\w ${c_lred}#${c_reset} "
  else
    PS1="${c_blue}\u${c_cyan}@\h${c_reset}: ${c_green}\w ${c_dgray}>${c_reset} "
  fi

  # 4. Clean up all temporary variables so they leave zero footprint in your shell
  unset c_red c_lred c_green c_blue c_cyan c_dgray c_reset
fi

###############################################################################
# Ensure terminal tab titles have info about the current state
#

# 3. Zero-fork tab title updater using Zsh built-in prompt expansion (%n=user, %m=short host, %1~=tail dir)
_set_tab_title() {
  # Guard so escape codes aren't printed in non-interactive shells or unsupported terminals
  [[ -o interactive ]] || return

    case "$TERM" in
      xterm*|rxvt|Eterm|eterm|linux)
        # Sets outer terminal window/tab title: OSC 0/1
        print -Pn "\e]1;%n@%m:…/%1~\a"
        # alternate, with no hostname:
        # print -Pn "\e]1;%n@…/%1~\a"
        ;;
      screen*|tmux*)
        # Sets both multiplexer internal title (APC) and outer terminal title (OSC 1)
        print -Pn "\e_%n@%m:…/%1~\a\e\\\e]1;%n@%m:…/%1~\a"
        ;;
    esac
}

# Add a hook and then run on shell startup so we don't wait for chdir
add-zsh-hook precmd _set_tab_title
_set_tab_title

###############################################################################
# Do our best to identify the mount type of the current directory
#

# This is the device ID mounted on /, which we need to identify "not mounted"
# directories. I'd prefer it not be global but that's better than calling stat
# twice on every directory change. We'll set it later when needed.
typeset -g _root_device_id="<NULL>"

# Export variables so the external Starship binary can read them via [env_var]
if [[ "$OSTYPE" == darwin* ]]; then
  # BSD stat on MacOS: %Sd returns block device name (e.g. "disk3s1") or "???" for network/virtual mounts
  _stat_cmd() { command stat -f "%Sd" "$1" 2>/dev/null; }
else
  # GNU stat on Linux: %i is unique filesystem ID, %T is filesystem type
  _stat_cmd() { command stat -f -c "%i:%T" "$1" 2>/dev/null; }
fi

_set_mount_icon() {

  # Icons used below:
  # Disk:    💾 or nerdfont: 󱊞 (nf-md-usb_flash_drive), 󱊟 (nf-md-usb_flash_drive_outline), or  (nf-fa-hard_drive)
  # Network: 🌐 or nerdfont: 󰒍 (nf-md-server_network)
  # System:  ⚙️ or nerdfont:  (nf-oct-gear)
  # Virtual: ☁️ or nerdfont:  (nf-fa-cloud)
  # Other:   📂 or nerdfont: 󰝰 (nf-md-folder_open) or 󰷏 (nf-md-folder_open_outline)

  local _is_macos=0
  [[ "$OSTYPE" == darwin* ]] && _is_macos=1

  local _abs_pwd="$PWD"

  # Loop in case we need to resolve symlinks
  local _resolved=0
  while true; do
    case "$_abs_pwd" in
      /media/*|/mnt/*|/net/*|/Network/*|/run/media/*|/run/user/*|/Volumes/*)
        # Exit the loop and process the icon using `stat` below.
        break
        ;;
      /dev|/dev/*|/Network|/proc|/proc/*|/run|/run/*|/sys|/sys/*|/System|/System/*|/Volumes)
        export MOUNT_ICON="⚙️"
        return
        ;;
      "$HOME/Library/CloudStorage/"|"$HOME/Library/CloudStorage/"*|"$HOME/Library/Mobile Documents"|"$HOME/Library/Mobile Documents"/*)
        export MOUNT_ICON="☁️"
        return
        ;;
      *)
        # We're safe to return early if we passed checks the second time through the loop.
        if (( _resolved )); then
          unset MOUNT_ICON
          return
        fi
        # Resolve symlinks in the path
        _abs_pwd="${PWD:A}"
        _resolved=1
        ;;
    esac
  done

  # Load some info about the device that hosts the current path
  local _info _device_id
  _info=$(_stat_cmd .)
  _device_id="${_info%%:*}"
  if (( _is_macos )); then
    # Strip off the partition number so we just have e.g. disk3 as the device
    _device_id="${_device_id%s*}"
  fi

  # Check the device id against the root device. This catches mounted paths that
  # symlink back to the root device.
  if [[ -n "$_device_id" ]]; then
    # Lazy load _root_device_id
    if [[ "$_root_device_id" == "<NULL>" ]]; then
      _root_device_id=$(_stat_cmd /)
      _root_device_id="${_root_device_id%%:*}"
      if (( _is_macos )); then
        # Strip off the partition number so we just have e.g. disk3 as the device
        _root_device_id="${_root_device_id%s*}"
      fi
    fi
    # No mount icon when we're on the root device
    if [[ "$_device_id" == "$_root_device_id" ]]; then
      unset MOUNT_ICON
      return
    fi
  fi

  # macOS branch: no fstype from stat, so we have less granularity
  if (( _is_macos )); then
    case "$_device_id" in
      disk*)
        export MOUNT_ICON="💾"
        ;;
      "???")
        export MOUNT_ICON="🌐"
        ;;
      *)
        export MOUNT_ICON="📂"
        ;;
    esac
    return
  fi

  # Linux branch: fstype from gnu stat, stored after the : in $_info
  local _fs_type="${_info#*:}"
  case "$_fs_type" in
    smbfs|smb2|cifs|nfs|nfs4|afpfs|webdav|9p)
      export MOUNT_ICON="💾"
      ;;
    fuse*|macfuse|osxfuse)
      case "$_abs_pwd" in
        /media/*|/run/media/*)
          export MOUNT_ICON="💾"
          ;;
        *)
          export MOUNT_ICON="☁️"
          ;;
      esac
      ;;
    apfs|hfs|ext2|ext3|ext4|btrfs|xfs|zfs|msdos|vfat|exfat|ntfs|fuseblk|cd9660|iso9660|udf)
      export MOUNT_ICON="💾"
      ;;
    autofs|tmpfs|sysfs)
      # Note: autofs fstype is for the parent directory (actual mounts will show as nfs, etc)
      export MOUNT_ICON="⚙️"
      ;;
    *)
      export MOUNT_ICON="📂"
      ;;
  esac
}

# Add a hook and then run on shell startup so we don't wait for chdir
add-zsh-hook chpwd _set_mount_icon
_set_mount_icon

