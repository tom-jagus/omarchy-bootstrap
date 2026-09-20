#!/usr/bin/env bash
# Preview the full removal transaction, including newly unneeded dependencies.
# Uses Omarchy's remover (pacman -Rns), never forced/cascading removal or a
# system-wide orphan purge. The checked-in removal list authorizes this step;
# print the transaction for visibility, but do not request another confirmation.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/../../omarchy/defaults.conf"
protected=$(bash "$script_dir/install.sh" --list-packages)
installed=$(pacman -Qq)
packages=()
while read -r package extra; do
  [[ -z $package || $package == \#* ]] && continue
  [[ -z $extra && $package =~ ^[a-zA-Z0-9][a-zA-Z0-9@._+-]*$ ]] || { echo "Invalid removal entry: $package $extra" >&2; exit 1; }
  if [[ $package == "$TERMINAL" ]] || grep -Fxq -- "$package" <<< "$protected"; then
    echo "Package listed for both retention/installation and removal: $package" >&2
    exit 1
  fi
  if grep -Fxq -- "$package" <<< "$installed"; then packages+=("$package"); fi
done < "$script_dir/../remove"
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
    *) echo 'Keeping Chromium: no verified webapp-compatible replacement is selected. Edit packages/remove before retrying.' >&2; exit 1 ;;
  esac
  pacman -Q "$replacement" >/dev/null
fi

printf '\nProposed removal transaction (including unneeded dependencies):\n'
# Also checks that dependency constraints permit the transaction.
pacman -Rns --print --print-format '%n' "${packages[@]}"
omarchy pkg drop "${packages[@]}"
