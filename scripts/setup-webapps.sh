#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/validate-config.sh"
config="$script_dir/../config/webapps.json"
apps="$HOME/.local/share/applications"
mkdir -p "$apps"

# Remove only launchers that are demonstrably Omarchy webapps, not native apps
# with the same name.
while IFS= read -r name; do
  file="$apps/$name.desktop"
  if [[ -L $file ]]; then
    echo "Refusing to modify a linked launcher: $file" >&2; exit 1
  elif [[ -f $file ]] && grep -Eq '^Exec=.*(omarchy-launch-webapp|omarchy-webapp-handler)' "$file"; then
    OMARCHY_REMOVE_NOTIFY=false omarchy webapp remove "$name"
  fi
done < <(jq -r '.remove[]' "$config")

while IFS= read -r entry; do
  name=$(jq -r '.name' <<< "$entry")
  url=$(jq -r '.url' <<< "$entry")
  icon=$(jq -r '.icon' <<< "$entry")
  file="$apps/$name.desktop"
  if [[ -e $file || -L $file ]]; then
    # On a retry, preserve an existing launcher rather than synchronizing it.
    echo "Existing launcher left untouched: $name"
    continue
  fi
  omarchy webapp install "$name" "$url" "$icon"
  [[ -f $file ]] || { echo "Launcher was not created: $name" >&2; exit 1; }
done < <(jq -c '.install[]' "$config")
