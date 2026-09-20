#!/usr/bin/env bash
# Usage: ./apply-shell-overrides.sh [path/to/shell.json]
# Defaults to the live user configuration. Requires an existing shell.json.
# Objects merge recursively; arrays and scalar values are replaced.
# This owns the bar layout and plugin list, not other shell settings.
# Plugins must be installed separately. The live shell hot-reloads changes.
set -euo pipefail

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  printf 'Usage: %s [path/to/shell.json]\nDefault: $XDG_CONFIG_HOME/omarchy/shell.json (or ~/.config/omarchy/shell.json)\n' "$0"
  exit 0
fi
if (( $# > 1 )); then
  echo 'Expected at most one target path.' >&2
  exit 1
fi
command -v jq >/dev/null || { echo 'Required command missing: jq' >&2; exit 1; }

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
overrides="$script_dir/../shell-overrides.json"
target=${1:-${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json}

# Do not accidentally replace a symlink managed by a dotfiles tool.
if [[ ! -f $target || -L $target ]]; then
  echo "Target must be an existing regular file, not a symlink: $target" >&2
  exit 1
fi

# Reject malformed JSON, multiple documents, and non-object roots.
for file in "$target" "$overrides"; do
  if ! jq -e -s 'length == 1 and (.[0] | type == "object")' "$file" >/dev/null; then
    echo "Expected one JSON object in: $file" >&2
    exit 1
  fi
done

# Stage in the destination directory so replacement is atomic.
tmp=$(mktemp "$(dirname -- "$target")/.shell-merge.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
jq -s '.[0] * .[1]' "$target" "$overrides" > "$tmp"

# Validate the sections we manage before touching the destination.
jq -e '
  def entries: type == "array" and all(.[]; type == "object" and (.id | type == "string"));
  (.bar.layout.left | entries) and
  (.bar.layout.center | entries) and
  (.bar.layout.right | entries) and
  (.plugins | entries)
' "$tmp" >/dev/null

# Avoid rewriting/hot-reloading when the merged configuration is unchanged.
if diff -q <(jq -S . "$target") <(jq -S . "$tmp") >/dev/null; then
  echo "Already up to date: $target"
  exit 0
fi

chmod --reference="$target" "$tmp"
mv -f -- "$tmp" "$target"
printf 'Applied shell overrides: %s\n' "$target"
