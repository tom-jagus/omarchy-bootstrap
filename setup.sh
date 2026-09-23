#!/usr/bin/env bash
# Fresh-install bootstrap. Not a daily configuration synchronization tool.
# Run as your regular user in a terminal inside the Omarchy desktop session.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo 'Usage: ./setup.sh'
  echo 'First-run agent/dictation, packages/defaults, targeted cleanup, plugins and shell.'
  echo 'Hyprland integration is delegated to omarchy-hypr-dotfiles/setup.sh.'
  exit 0
fi
(( $# == 0 )) || { echo 'Unexpected arguments.' >&2; exit 1; }
(( EUID != 0 )) || { echo 'Run as your desktop user, not root.' >&2; exit 1; }
[[ -t 0 && -t 1 ]] || { echo 'Run interactively in a terminal.' >&2; exit 1; }
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || { echo 'Run inside your Omarchy Hyprland session.' >&2; exit 1; }
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || { echo 'Omarchy installers require ~/.config.' >&2; exit 1; }
for command in omarchy pacman jq python3 git sudo mise xdg-settings xdg-mime; do
  command -v "$command" >/dev/null || { echo "Required command missing: $command" >&2; exit 1; }
done
[[ -f $HOME/.config/omarchy/shell.json && ! -L $HOME/.config/omarchy/shell.json ]] || {
  echo 'Expected the fresh-install shell.json, not a missing file or symlink.' >&2; exit 1;
}

# Fail on malformed preferences before touching the machine.
bash "$root/scripts/validate-config.sh"

# Also prepare the layout when setup.sh is run directly from a manual clone.
bash "$root/scripts/setup-directories.sh"

printf 'Applying the checked-in packages, defaults, webapps, and desktop configuration.\n'
printf 'Sudo, dictation setup, and package removal confirmation may require input.\n'
sudo -v

bash "$root/scripts/setup-onboarding.sh"
bash "$root/scripts/setup-packages.sh"
bash "$root/scripts/setup-defaults.sh"
bash "$root/scripts/remove-packages.sh"
bash "$root/scripts/setup-webapps.sh"
bash "$root/scripts/setup-shell.sh"
bash "$root/scripts/setup-hypr.sh"
printf '\nApplication, shell, and Hyprland bootstrap complete. Log out and back in for autostart.\n'
