#!/usr/bin/env bash
# Download this file from a specific Git commit, inspect it, then execute with
# --ref <the same full commit hash>. Do not pipe into Bash: setup needs stdin.
set -euo pipefail

fail() { printf 'bootstrap: %s\n' "$*" >&2; exit 1; }
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo 'Usage: bash bootstrap.sh --ref <full-40-character-commit-hash>'
  echo 'Clones/reuses ~/src/personal/omarchy-bootstrap and runs its setup.sh.'
  exit 0
fi
[[ $# == 2 && $1 == --ref && $2 =~ ^[0-9a-f]{40}$ ]] || fail 'Pass --ref followed by a full lowercase Git commit hash.'
revision=$2
(( EUID != 0 )) || fail 'Run as your desktop user, not root.'
[[ -t 0 && -t 1 ]] || fail 'Download this script, then run it in an interactive terminal (not a pipe).'
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || fail 'Run inside your Omarchy Hyprland session.'
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || fail 'Omarchy installers require ~/.config.'
for command in git omarchy pacman jq python3 sudo mise xdg-settings xdg-mime cmp; do
  command -v "$command" >/dev/null || fail "Required command missing: $command"
done
[[ -f $HOME/.config/omarchy/shell.json && ! -L $HOME/.config/omarchy/shell.json ]] || fail 'Expected the fresh-install ~/.config/omarchy/shell.json.'

# Keep this tiny standalone step in sync with scripts/setup-directories.sh.
# The entry point has not cloned that script yet.
mkdir -p -- "$HOME/src/personal" "$HOME/dev/personal" "$HOME/dev/clients"
repository=https://github.com/tom-jagus/omarchy-bootstrap.git
target="$HOME/src/personal/omarchy-bootstrap"
entry=$(realpath -- "${BASH_SOURCE[0]}")
stage=''
trap 'if [[ -n $stage ]]; then rm -rf -- "$stage"; fi' EXIT

if [[ -e $target || -L $target ]]; then
  [[ -d $target && ! -L $target && -d $target/.git ]] || fail "Existing target is not a regular Git checkout: $target"
  origin=$(git -C "$target" remote get-url origin) || fail 'Existing checkout has no origin.'
  case "$origin" in
    "$repository"|git@github.com:tom-jagus/omarchy-bootstrap.git) ;;
    *) fail "Existing checkout has an unexpected origin: $origin" ;;
  esac
  [[ $(git -C "$target" rev-parse HEAD) == "$revision" ]] || fail 'Existing checkout is at a different commit. Review/update it manually; nothing was reset or pulled.'
  [[ -z $(git -C "$target" status --porcelain --untracked-files=all) ]] || fail 'Existing checkout has local changes. Preserve/review them before retrying.'
  checkout=$target
else
  stage=$(mktemp -d "$HOME/src/personal/.omarchy-bootstrap.XXXXXX")
  GIT_TERMINAL_PROMPT=0 git clone --no-checkout -- "$repository" "$stage"
  git -C "$stage" -c advice.detachedHead=false checkout --detach "$revision"
  [[ $(git -C "$stage" rev-parse HEAD) == "$revision" ]] || fail 'Checkout does not match requested commit.'
  checkout=$stage
fi

# The downloaded entry point must match the pinned checkout, preventing an
# accidental mix of entry-point and setup versions. This is not signature verification.
[[ -f $checkout/bootstrap.sh && ! -L $checkout/bootstrap.sh ]] || fail 'Pinned commit has no regular bootstrap.sh.'
cmp -s -- "$entry" "$checkout/bootstrap.sh" || fail 'Downloaded entry point differs from the requested commit. Download it from that commit and retry.'
[[ -f $checkout/setup.sh && ! -L $checkout/setup.sh ]] || fail 'Pinned commit has no regular setup.sh.'

if [[ -n $stage ]]; then
  # -T refuses to nest the clone in a directory created concurrently.
  [[ ! -e $target && ! -L $target ]] || fail 'Destination appeared while cloning; refusing to overwrite it.'
  mv -T -- "$stage" "$target"
  stage=''
fi
printf 'Running pinned bootstrap checkout: %s (%s)\n' "$target" "$revision"
exec bash "$target/setup.sh"
