#!/usr/bin/env python3
"""Set up my preferred shell environment, etc.

Two ways to install the files declared in INSTALL below:

  local   (default)  create $HOME-relative *symlinks* into this checked-out
                     repo, so a later `git pull` updates your config in place.
  remote             copy the same files (via rsync) into the remote user's
                     home directory (~ is expanded on the *remote* side, so
                     the remote OS/home layout doesn't have to match local).

INSTALL maps a path *in this repo* -> where it should live under $HOME.
The destination directory (e.g. ".config") is created as needed.  Values:
  - a path  => destination relative to $HOME
  - True    => destination mirrors the source name
  - False   => entry is skipped
Trailing slashes on keys/values are insignificant.  For example:

    "starship.toml": ".config/starship.toml"   =>   $HOME/.config/starship.toml
    ".zsh":          True                      =>   $HOME/.zsh

Usage:
    ./setup.py                          # local: create symlinks
    ./setup.py --dry-run                # local: preview only, change nothing
    ./setup.py --remote=host            # remote  (or: -r host)
    ./setup.py --remote=host --dry-run
"""

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

# Version guard (the bash version needed 4.4+; here a recent 3.x suffices).
if sys.version_info < (3, 7):
    sys.exit(f"setup: Python 3.7+ required (found {sys.version.split()[0]})")

REPO = Path(__file__).resolve().parent  # this dotfiles checkout
HOME = Path(
    os.path.expanduser("~")
).resolve()  # physical $HOME: keeps links resolvable even if $HOME is a symlink (e.g. /var -> /private)

# What we manage, per the module docstring.
#   local => symlink,  remote => copy (rsync).  Add / adjust freely.
INSTALL = {
    ".bashrc.d/": True,
    ".bashrc": True,
    ".gitconfig": True,
    ".inputrc": True,
    ".ripgreprc": True,
    ".vimrc": True,
    ".zsh/": True,
    ".zshrc": True,
    # "lsd/": ".config/lsd/",
    "starship.toml": ".config/starship.toml",
}


def entries():
    """Yield (src_rel, dest_rel) Path pairs for each *enabled* INSTALL entry.

    - A value of False skips the entry entirely.
    - A value of True makes the destination mirror the source.
    - Trailing slashes are dropped by Path(), so a directory is treated the
      same whether or not it ends in "/" in either the key or a string value.
    """
    for src_rel, dest in INSTALL.items():
        src_rel = Path(src_rel)
        if dest is False:  # explicitly disabled
            continue
        yield src_rel, src_rel if dest is True else Path(dest)


# Preview / act layer: set once from --dry-run, read by run() and act().
DRY_RUN = False


def info(msg: str) -> None:
    print(f"INFO:      {msg}")


def warn(msg: str) -> None:
    print(f"WARNING:   {msg}", file=sys.stderr)


def die(msg: str, code: int = 1) -> None:
    print(f"ERROR:     {msg}", file=sys.stderr)
    sys.exit(code)


def run(cmd: list[str]) -> None:
    """Run an external command, or just print it under --dry-run."""
    line = " ".join(shlex.quote(c) for c in cmd)
    if DRY_RUN:
        print(f"DRY-RUN:     {line}")
        return
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        die(f"failed (exit {e.returncode}): {line}")


def act(action, desc: str) -> None:
    """Perform local file `action`, or print `desc` under --dry-run.

    The in-process analogue of run() for filesystem ops, so the symlink/backup
    logic shares the same preview behaviour without shelling out.
    """
    if DRY_RUN:
        print(f"DRY-RUN:     {desc}")
    else:
        action()


# ---------------------------------------------------------------------------
# LOCAL mode: $HOME-relative symlinks
# ---------------------------------------------------------------------------
def make_link(link: Path, src: Path) -> None:
    """Symlink `link` -> `src`, targeting a path relative to `link`'s directory."""
    rel = os.path.relpath(src, link.parent)

    # Ensure the destination directory exists (only for subdirs like .config).
    if link.parent != HOME:
        act(
            lambda: link.parent.mkdir(parents=True, exist_ok=True),
            f"mkdir -p {link.parent}",
        )

    # Move any existing real file/dir out of the way; drop a stale link.
    if link.is_symlink():
        act(link.unlink, f"rm {link}")
    elif link.exists():
        backup = link.with_name(link.name + ".bak" + time.strftime("%Y%m%d%H%M%S"))
        act(lambda: link.rename(backup), f"mv {link} {backup}")
        if not DRY_RUN:
            warn(f"backed up existing {link} -> {backup}")

    act(lambda: link.symlink_to(rel), f"ln -s {rel} {link}")
    if not DRY_RUN:
        info(f"linked {link} -> {rel}")


def install_local() -> None:
    info(
        (
            "local dry run — no changes will be made"
            if DRY_RUN
            else f"installing locally into {HOME} (symlinks)"
        )
    )
    for src_rel, dest_rel in entries():
        src = REPO / src_rel
        if not src.exists():
            warn(f"skipping {src_rel} (not found in repo at {src})")
            continue
        make_link(HOME / dest_rel, src)


# ---------------------------------------------------------------------------
# REMOTE mode: rsync each file into the target's $HOME (as copies)
# ---------------------------------------------------------------------------
def install_remote(target: str) -> None:
    info(
        (
            f"remote '{target}' dry run — no changes will be made"
            if DRY_RUN
            else f"installing on remote host '{target}' (rsync)"
        )
    )
    if not DRY_RUN and not shutil.which("rsync"):
        die("remote mode requires rsync; install it and try again")

    for src_rel, dest_rel in entries():
        src = REPO / src_rel
        if not src.exists():
            warn(f"skipping {src_rel} (not found in repo at {src})")
            continue

        # Remote paths are ~-relative: ssh/rsync expand ~ against the *remote*
        # user's home, so this works across platforms/usernames even when the
        # remote home differs from the local one (e.g. macOS -> Linux).
        dest = Path("~") / dest_rel  # e.g. ~/.config/starship.toml
        remote_dir = dest.parent  # e.g. ~/.config (or ~ itself)
        if remote_dir != Path("~"):
            run(["ssh", target, "mkdir -p", str(remote_dir)])
        # Trailing slash on the remote dir: file/dir keeps its basename inside it.
        run(["rsync", "-a", str(src), f"{target}:{remote_dir}/"])
        if not DRY_RUN:
            info(f"rsynced {src_rel} -> {target}:{dest}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def parse_args(argv=None) -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        prog="setup",
        description="Install the dotfiles from this repo (local by default).",
    )
    ap.add_argument(
        "-r",
        "--remote",
        metavar="TARGET",
        help="remote mode: rsync the files into TARGET's $HOME (host or user@host)",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="show what would be done without making any changes",
    )
    return ap.parse_args(argv)


def main(argv=None) -> None:
    global DRY_RUN
    args = parse_args(argv)
    DRY_RUN = args.dry_run
    if args.remote:
        install_remote(args.remote)
    else:
        install_local()


if __name__ == "__main__":
    try:
        main()
    except OSError as e:
        die(str(e))
