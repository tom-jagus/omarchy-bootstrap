#!/usr/bin/env bash
# Agent setup never launches the agent; dictation setup remains interactive.
# Run as the desktop user, never via sudo.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/validate-config.sh"
DICTATION=$(jq -r '.dictation' "$script_dir/../config/defaults.json")

bash "$script_dir/setup-agent.sh"

case "$DICTATION" in
  true)
    if pacman -Q voxtype-bin >/dev/null 2>&1 &&
       [[ -f $HOME/.config/voxtype/config.toml ]] &&
       systemctl --user is-enabled --quiet voxtype.service; then
      echo 'Dictation already configured; preserving it.'
    else
      omarchy voxtype install
      # The upstream installer can return success when its prompt is declined.
      pacman -Q voxtype-bin >/dev/null
      [[ -f $HOME/.config/voxtype/config.toml ]] && systemctl --user is-enabled --quiet voxtype.service || {
        echo 'Dictation setup was not completed. Retry, or set DICTATION=false.' >&2
        exit 1
      }
    fi
    ;;
  false) echo 'Dictation setup disabled in config/defaults.json.' ;;
  *) echo 'DICTATION must be true or false.' >&2; exit 1 ;;
esac
