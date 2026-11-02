#!/bin/sh
# ccs installer — https://github.com/galliva/ccs
#
#   curl -fsSL https://raw.githubusercontent.com/galliva/ccs/main/install.sh | sh
#   ./install.sh              from a clone: symlinks the checkout (git pull updates it)
#   ./install.sh --uninstall
#
# Environment: CCS_INSTALL_DIR (default ~/.local/bin), CCS_REPO (default galliva/ccs)
set -eu

REPO="${CCS_REPO:-galliva/ccs}"
BIN_DIR="${CCS_INSTALL_DIR:-$HOME/.local/bin}"
RAW="https://raw.githubusercontent.com/$REPO/main/ccs"
MIN_FZF="0.58"

say() { printf '%s\n' "$*"; }
die() { printf 'ccs install: %s\n' "$*" >&2; exit 1; }

if [ "${1:-}" = "--uninstall" ]; then
  rm -f "$BIN_DIR/ccs" && say "removed $BIN_DIR/ccs"
  say "kept your data: ~/.config/ccs (pins, state) and ~/.cache/ccs (index, trash)"
  exit 0
fi

# --- requirements -----------------------------------------------------------
command -v python3 >/dev/null 2>&1 || die "python3 is required"
command -v fzf >/dev/null 2>&1 || die "fzf is required (brew install fzf)"
ver=$(fzf --version 2>/dev/null | sed 's/[^0-9.].*//')
if [ "$(printf '%s\n%s\n' "$MIN_FZF" "$ver" | sort -t. -k1,1n -k2,2n | head -1)" != "$MIN_FZF" ]; then
  die "fzf $ver is too old, $MIN_FZF or newer is needed (brew upgrade fzf)"
fi
command -v claude >/dev/null 2>&1 || say "note: 'claude' is not in PATH; ccs will look in ~/.local/bin or use CCS_CLAUDE_BIN"

# --- install ----------------------------------------------------------------
mkdir -p "$BIN_DIR"
[ -d "$BIN_DIR/ccs" ] && die "$BIN_DIR/ccs is a directory; remove it or choose another CCS_INSTALL_DIR"
here=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P || true)
case "$0" in
  *install.sh) local_copy="$here/ccs" ;;
  *) local_copy="" ;;
esac

if [ -n "$local_copy" ] && [ -f "$local_copy" ]; then
  chmod +x "$local_copy"
  ln -sfn "$local_copy" "$BIN_DIR/ccs"
  say "linked $BIN_DIR/ccs -> $local_copy"
else
  command -v curl >/dev/null 2>&1 || die "curl is required to download ccs"
  tmp=$(mktemp "${TMPDIR:-/tmp}/ccs.XXXXXX")
  curl -fsSL "$RAW" -o "$tmp" || { rm -f "$tmp"; die "download failed: $RAW"; }
  head -1 "$tmp" | grep -q '^#!/usr/bin/env bash' || { rm -f "$tmp"; die "unexpected content downloaded from $RAW"; }
  chmod +x "$tmp"
  mv "$tmp" "$BIN_DIR/ccs"
  say "installed $BIN_DIR/ccs"
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) qdir=$(printf '%s' "$BIN_DIR" | sed "s/'/'\\\\''/g")
     say "add it to your PATH, e.g. in ~/.zshrc:  export PATH='$qdir':\"\$PATH\"" ;;
esac
say "done — run: ccs"
