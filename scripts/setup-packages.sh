#!/usr/bin/env bash
# Install the repo/AUR selections and the one dedicated Omarchy installer.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/validate-config.sh"
config="$script_dir/../config/packages.json"

for source in repo aur; do
  while IFS= read -r package; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      echo "Already installed: $package"
      continue
    fi
    if [[ $source == repo ]]; then
      omarchy pkg add "$package"
    else
      omarchy pkg aur add "$package"
    fi
    pacman -Q "$package" >/dev/null || { echo "Installation failed: $package" >&2; exit 1; }
  done < <(jq -r --arg source "$source" '.install[$source][]' "$config")
done

# Signal's Omarchy installer also opens the app. Keep special actions explicit,
# rather than encoding executable commands in the JSON file.
if pacman -Q signal-desktop >/dev/null 2>&1; then
  echo 'Already installed: signal-desktop'
else
  omarchy install service signal
  pacman -Q signal-desktop >/dev/null || { echo 'Installation failed: signal-desktop' >&2; exit 1; }
fi
