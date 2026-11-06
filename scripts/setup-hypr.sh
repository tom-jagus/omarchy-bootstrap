#!/usr/bin/env bash
# This repository only obtains the dotfiles and delegates their integration.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/validate-config.sh"
source_file="$script_dir/../config/defaults.json"
url=$(jq -r '.hypr.url' "$source_file")
ref=$(jq -r '.hypr.ref' "$source_file")
target="$HOME/src/default/omarchy-hypr-dotfiles"
mkdir -p -- "$HOME/src/default"
stage=''
trap 'if [[ -n $stage ]]; then rm -rf -- "$stage"; fi' EXIT

if [[ -e $target || -L $target ]]; then
  [[ -d $target && ! -L $target && -d $target/.git ]] || { echo "Unexpected checkout path: $target" >&2; exit 1; }
  origin=$(git -C "$target" remote get-url origin)
  ssh_url="git@github.com:${url#https://github.com/}"
  [[ $origin == "$url" || $origin == "$ssh_url" ]] || { echo "Unexpected origin: $origin" >&2; exit 1; }
  # No pull/reset/checkout: this is an actively maintained dotfiles repository.
  expected=$(git -C "$target" rev-parse --verify "$ref^{commit}")
  [[ $(git -C "$target" rev-parse HEAD) == "$expected" ]] || {
    echo 'Existing dotfiles checkout differs from the requested local ref. Review it manually.' >&2; exit 1;
  }
  echo "Reusing dotfiles checkout; local edits preserved: $target"
else
  stage=$(mktemp -d "$HOME/src/default/.omarchy-hypr-dotfiles.XXXXXX")
  GIT_TERMINAL_PROMPT=0 git clone -- "$url" "$stage"
  git -C "$stage" checkout "$ref"
  [[ -f $stage/setup.sh && ! -L $stage/setup.sh ]] || { echo 'Dotfiles ref has no setup.sh; publish the installer first.' >&2; exit 1; }
  [[ ! -e $target && ! -L $target ]] || { echo 'Checkout destination appeared during clone.' >&2; exit 1; }
  mv -T -- "$stage" "$target"
  stage=''
fi
[[ -f $target/setup.sh && ! -L $target/setup.sh ]] || { echo 'Dotfiles checkout has no regular setup.sh.' >&2; exit 1; }
bash "$target/setup.sh"
