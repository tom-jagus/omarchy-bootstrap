#!/usr/bin/env bash
# Remove unwanted plugins only after shell.json no longer references them.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/validate-config.sh"
plugins_dir="$HOME/.config/omarchy/plugins"
shell_config="$HOME/.config/omarchy/shell.json"
[[ -f $shell_config && ! -L $shell_config ]] || { echo "Expected a regular shell.json: $shell_config" >&2; exit 1; }
jq -e -s 'length == 1 and (.[0] | type == "object")' "$shell_config" >/dev/null
while IFS= read -r id; do
  target="$plugins_dir/$id"
  if [[ ! -e $target && ! -L $target ]]; then
    echo "Plugin already absent: $id"
    continue
  fi
  # The Omarchy remover deletes git checkouts; never discard local edits.
  if [[ -d $target/.git ]]; then
    status=$(git -C "$target" status --porcelain --untracked-files=all) || {
      echo "Cannot inspect plugin checkout; refusing to remove it: $target" >&2; exit 1;
    }
    [[ -z $status ]] || { echo "Plugin checkout has local changes; review it before removal: $target" >&2; exit 1; }
  fi
  if jq -e --arg id "$id" '[ .. | objects | .id? ] | index($id) != null' "$shell_config" >/dev/null; then
    echo "Plugin is still referenced by shell.json: $id" >&2
    exit 1
  fi
  omarchy plugin remove "$id"
done < <(jq -r '.remove[]' "$script_dir/../config/plugins.json")
