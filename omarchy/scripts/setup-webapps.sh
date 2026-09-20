#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
apps="$HOME/.local/share/applications"
list="$script_dir/../webapps/install.json"
# Validate all records before removing or creating any launcher.
jq -e -s '
  length == 1 and (.[0] |
    type == "array" and
    all(.[]; type == "object" and
      (.name | type == "string" and length > 0 and (test("[/\\x00-\\x1f]") | not)) and
      (.url | type == "string" and test("^https://[^[:space:]]+$")) and
      (.icon | type == "string" and test("^[a-zA-Z0-9_.-]+$"))) and
    (map(.name) | length == (unique | length)))
' "$list" >/dev/null
entries=$(jq -c '.[]' "$list")
mkdir -p "$apps"

# Delete only launchers that are demonstrably Omarchy webapps. Never delete a
# native Discord/Zoom launcher just because it has the same filename.
while IFS= read -r name || [[ -n $name ]]; do
  [[ -z $name || $name == \#* ]] && continue
  [[ $name != */* ]] || { echo "Invalid webapp name: $name" >&2; exit 1; }
  file="$apps/$name.desktop"
  if [[ -L $file ]]; then
    echo "Refusing to modify a linked launcher: $file" >&2; exit 1
  elif [[ -f $file ]] && grep -Eq '^Exec=.*(omarchy-launch-webapp|omarchy-webapp-handler)' "$file"; then
    OMARCHY_REMOVE_NOTIFY=false omarchy webapp remove "$name"
  fi
done < "$script_dir/../webapps/remove"

while IFS= read -r entry; do
  [[ -n $entry ]] || continue
  name=$(jq -r '.name' <<< "$entry")
  url=$(jq -r '.url' <<< "$entry")
  icon=$(jq -r '.icon' <<< "$entry")
  file="$apps/$name.desktop"
  if [[ -e $file || -L $file ]]; then
    # Preserve existing launchers on a setup retry; differing preferences are
    # intended for a fresh install, not continuous synchronization.
    echo "Existing launcher left untouched: $name"
    continue
  fi
  omarchy webapp install "$name" "$url" "$icon"
  [[ -f $file ]] || { echo "Launcher was not created: $name" >&2; exit 1; }
done <<< "$entries"
