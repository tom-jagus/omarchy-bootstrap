#!/usr/bin/env bash
# Show the exact pacman -Rns transaction before removing checked-in choices.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/validate-config.sh"
config="$script_dir/../config/packages.json"
terminal=$(jq -r '.terminal' "$script_dir/../config/defaults.json")
protected=$(jq -r '.install.repo[], .install.aur[]' "$config")
installed=$(pacman -Qq)
packages=()
while IFS= read -r package; do
  if [[ $package == "$terminal" || $package == signal-desktop ]] || grep -Fxq -- "$package" <<< "$protected"; then
    echo "Package listed for both retention/installation and removal: $package" >&2
    exit 1
  fi
  if grep -Fxq -- "$package" <<< "$installed"; then packages+=("$package"); fi
done < <(jq -r '.remove[]' "$config")
(( ${#packages[@]} )) || { echo 'No listed packages remain to remove.'; exit 0; }

if printf '%s\n' "${packages[@]}" | grep -Fxq chromium; then
  # Omarchy webapps fall back to Chromium for Firefox/Zen and unknown browsers.
  browser=$(env -u BROWSER xdg-settings get default-web-browser)
  case "$browser" in
    vivaldi-stable.desktop) replacement=vivaldi ;;
    google-chrome.desktop) replacement=google-chrome ;;
    brave-browser.desktop) replacement=brave-bin ;;
    brave-origin.desktop) replacement=brave-origin-bin ;;
    microsoft-edge.desktop) replacement=microsoft-edge-stable-bin ;;
    *) echo 'Keeping Chromium: no verified webapp-compatible replacement is selected. Edit config/packages.json before retrying.' >&2; exit 1 ;;
  esac
  pacman -Q "$replacement" >/dev/null
fi

printf '\nProposed removal transaction (including unneeded dependencies):\n'
pacman -Rns --print --print-format '%n' "${packages[@]}"
read -r -p 'Remove these packages? [y/N] ' answer
[[ $answer == y || $answer == Y ]] || { echo 'Skipping package removal.'; exit 0; }
omarchy pkg drop "${packages[@]}"
