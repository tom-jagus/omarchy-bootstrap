#!/usr/bin/env bash
# Install missing plugins using Omarchy's validated installer, without enabling
# them or updating existing checkouts. Plugin code runs unsandboxed: only list
# trusted repositories in config/plugins.json. New installs use upstream's current HEAD.
set -euo pipefail

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo 'Usage: setup-plugins.sh (installs missing entries from config/plugins.json)'
  exit 0
fi
(( $# == 0 )) || { echo 'Unexpected arguments.' >&2; exit 1; }
for command in omarchy jq; do
  command -v "$command" >/dev/null || { echo "Required command missing: $command" >&2; exit 1; }
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Omarchy's plugin installer currently uses this path, not XDG_CONFIG_HOME.
plugins_dir="$HOME/.config/omarchy/plugins"

bash "$script_dir/validate-config.sh"
sources="$script_dir/../config/plugins.json"
entries=$(jq -c '.install[]' "$sources")
while IFS= read -r entry; do
  [[ -n $entry ]] || continue
  id=$(jq -r '.id' <<< "$entry")
  url=$(jq -r '.url' <<< "$entry")
  target="$plugins_dir/$id"
  if [[ -e $target || -L $target ]]; then
    # Never overwrite an existing directory, symlink, or locally modified repo.
    if [[ ! -f $target/manifest.json ]] || ! jq -e --arg id "$id" '.id == $id' "$target/manifest.json" >/dev/null; then
      echo "Existing plugin path has no matching manifest: $target" >&2
      exit 1
    fi
    echo "Already installed, leaving untouched: $id"
    continue
  fi

  omarchy plugin add "$url" --yes
  jq -e --arg id "$id" '.id == $id' "$target/manifest.json" >/dev/null || {
    echo "Installation did not produce expected plugin: $id" >&2
    exit 1
  }
done <<< "$entries"
