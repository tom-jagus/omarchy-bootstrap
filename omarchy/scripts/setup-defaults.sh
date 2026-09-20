#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/../defaults.conf"

# Omarchy installs the terminal, creates its desktop integration, and selects it.
omarchy install terminal "$TERMINAL"
pacman -Q "$TERMINAL" >/dev/null
[[ $(omarchy default terminal) == "$TERMINAL" ]] || { echo 'Terminal selection failed.' >&2; exit 1; }

case "$BROWSER" in
  vivaldi)
    # Vivaldi is not supported by Omarchy's dedicated browser installer yet.
    omarchy pkg add vivaldi
    desktop=vivaldi-stable.desktop
    env -u BROWSER xdg-settings set default-web-browser "$desktop"
    ;;
  chromium)
    omarchy pkg add chromium
    omarchy default browser chromium
    desktop=chromium.desktop
    ;;
  chrome|brave|brave-origin|edge|firefox|zen)
    omarchy install browser "$BROWSER"
    omarchy default browser "$BROWSER"
    desktop=$(env -u BROWSER xdg-settings get default-web-browser)
    ;;
  *) echo "Unsupported browser preference: $BROWSER" >&2; exit 1 ;;
esac
[[ $(env -u BROWSER xdg-settings get default-web-browser) == "$desktop" ]] || { echo 'Browser selection failed.' >&2; exit 1; }
for mime in text/html x-scheme-handler/http x-scheme-handler/https; do
  xdg-mime default "$desktop" "$mime"
done
