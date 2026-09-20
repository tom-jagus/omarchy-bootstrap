#!/usr/bin/env bash
# Shell-only orchestrator. Does not install Hyprland configuration.
# Run inside the installed Omarchy graphical session (plugin add uses its IPC).
set -euo pipefail

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo 'Usage: setup-shell.sh'
  echo 'Installs missing plugins, patches the tray, then applies shell overrides.'
  exit 0
fi
(( $# == 0 )) || { echo 'Unexpected arguments.' >&2; exit 1; }

# Plugin installation is currently hardcoded to ~/.config by Omarchy itself.
if [[ ${XDG_CONFIG_HOME:-$HOME/.config} != "$HOME/.config" ]]; then
  echo 'Custom XDG_CONFIG_HOME is not supported by Omarchy plugin installation.' >&2
  exit 1
fi
for command in omarchy jq python3; do
  command -v "$command" >/dev/null || { echo "Required command missing: $command" >&2; exit 1; }
done
shell_config="$HOME/.config/omarchy/shell.json"
[[ -f $shell_config && ! -L $shell_config ]] || {
  echo "Expected an existing shell configuration, not a symlink: $shell_config" >&2
  exit 1
}
jq -e -s 'length == 1 and (.[0] | type == "object")' "$shell_config" >/dev/null

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/scripts/install-plugins.sh"
bash "$script_dir/scripts/patch-tray.sh"
bash "$script_dir/scripts/apply-shell-overrides.sh" "$shell_config"
