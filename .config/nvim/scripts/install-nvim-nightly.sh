#!/usr/bin/env bash
# install-nvim-nightly.sh — download a Neovim release, extract it under a
# self-contained prefix, and symlink its binary onto $PATH. No Homebrew.
#
# Usage:
#   ./install-nvim-nightly.sh [channel]
#     channel : nightly (default) | stable
#
# Env overrides:
#   NVIM_PREFIX    install root            (default: ~/.local/nvim-<channel>)
#   NVIM_BIN_LINK  symlink to create       (default: /usr/local/bin/nvim)
#
# Safe to re-run: the prefix is replaced atomically-ish (staged, then swapped)
# and the symlink is refreshed in place.
set -euo pipefail

CHANNEL="${1:-nightly}"
case "$CHANNEL" in
  nightly | stable) ;;
  *)
    echo "error: channel must be 'nightly' or 'stable' (got '$CHANNEL')" >&2
    exit 2
    ;;
esac

PREFIX="${NVIM_PREFIX:-$HOME/.local/nvim-$CHANNEL}"
BIN_LINK="${NVIM_BIN_LINK:-/usr/local/bin/nvim}"

# --- Resolve the release asset for this OS/arch --------------------------
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Darwin) os_tag="macos" ;;
  Linux)  os_tag="linux" ;;
  *) echo "error: unsupported OS '$os'" >&2; exit 1 ;;
esac
case "$arch" in
  arm64 | aarch64) arch_tag="arm64" ;;
  x86_64 | amd64)  arch_tag="x86_64" ;;
  *) echo "error: unsupported arch '$arch'" >&2; exit 1 ;;
esac

asset="nvim-${os_tag}-${arch_tag}.tar.gz"
url="https://github.com/neovim/neovim/releases/download/${CHANNEL}/${asset}"

echo "==> channel : $CHANNEL"
echo "==> asset   : $asset"
echo "==> prefix  : $PREFIX"
echo "==> symlink : $BIN_LINK"

# --- Download ------------------------------------------------------------
tmp="$(mktemp -d "${TMPDIR:-/tmp}/nvim-nightly.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
tarball="$tmp/$asset"

echo "==> downloading $url"
if ! curl -fL --retry 3 --proto '=https' --tlsv1.2 -o "$tarball" "$url"; then
  echo "error: download failed. Does the '$asset' asset exist for '$CHANNEL'?" >&2
  exit 1
fi

# Sanity-check it is actually a gzip tarball, not an HTML error page.
if ! tar -tzf "$tarball" >/dev/null 2>&1; then
  echo "error: downloaded file is not a valid tar.gz (got an error page?)" >&2
  exit 1
fi

# --- Extract into a staging dir, then swap into place --------------------
stage="$tmp/stage"
mkdir -p "$stage"
# The tarball's single top-level dir is stripped so bin/ lib/ share/ land flat.
tar -xzf "$tarball" --strip-components=1 -C "$stage"

if [ ! -x "$stage/bin/nvim" ]; then
  echo "error: extracted archive has no bin/nvim" >&2
  exit 1
fi

# Best-effort: clear the quarantine xattr so the unsigned nightly runs cleanly.
xattr -dr com.apple.quarantine "$stage" 2>/dev/null || true

mkdir -p "$(dirname "$PREFIX")"
rm -rf "$PREFIX"
mv "$stage" "$PREFIX"

# --- Symlink onto PATH (sudo only if the target dir is not writable) -----
link_dir="$(dirname "$BIN_LINK")"
maybe_sudo=""
if [ ! -d "$link_dir" ]; then
  if mkdir -p "$link_dir" 2>/dev/null; then :; else maybe_sudo="sudo"; fi
fi
if [ -n "$maybe_sudo" ] || { [ -e "$link_dir" ] && [ ! -w "$link_dir" ]; }; then
  maybe_sudo="sudo"
  echo "==> $link_dir is not writable; using sudo for the symlink"
fi
$maybe_sudo mkdir -p "$link_dir"
$maybe_sudo ln -sfn "$PREFIX/bin/nvim" "$BIN_LINK"

# --- Verify --------------------------------------------------------------
echo "==> linked  $BIN_LINK -> $PREFIX/bin/nvim"
echo "==> version:"
"$PREFIX/bin/nvim" --version | head -3

if ! command -v nvim >/dev/null 2>&1; then
  echo ""
  echo "note: 'nvim' is not on your PATH yet. Ensure '$link_dir' is on \$PATH."
fi
echo "==> done."
