#!/usr/bin/env bash
# Install/select an agent without launching it or requesting authentication.
# Omarchy's default-agent setter always launches the agent, so use its same
# mise package mapping and preference file without calling that setter.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/../defaults.conf"

case "$AGENT" in
  pi|opencode|claude|codex|crush|gemini|copilot|cursor-agent) package=$AGENT ;;
  omp) package=github:can1357/oh-my-pi ;;
  grok) package=npm:@xai-official/grok ;;
  *) echo "Unsupported non-launching agent setup: $AGENT. Add its installer mapping before using it." >&2; exit 1 ;;
esac
command -v mise >/dev/null || { echo 'Required command missing: mise' >&2; exit 1; }
agent_file="$HOME/.config/omarchy/defaults/agent"
[[ ! -L $agent_file && ( ! -e $agent_file || -f $agent_file ) ]] || {
  echo "Refusing to replace a linked or non-file agent preference: $agent_file" >&2; exit 1;
}

# Querying an executable on PATH is insufficient: Omarchy provides lazy-install
# stubs before the actual agent exists. Never execute the agent to check it.
selected=''
if [[ -f $agent_file ]]; then selected=$(< "$agent_file"); fi
if [[ $selected == "$AGENT" ]] && (cd "$HOME" && mise where "$package" >/dev/null 2>&1); then
  echo "Agent already installed and selected: $AGENT"
  exit 0
fi
(cd "$HOME" && MISE_YES=1 mise use --global "$package")
(cd "$HOME" && mise where "$package" >/dev/null)

# Select only after installation succeeded. This is the file Omarchy's getter
# reads, not a new configuration mechanism. No login or agent process is started.
mkdir -p -- "$(dirname -- "$agent_file")"
tmp=$(mktemp "$(dirname -- "$agent_file")/.agent.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf '%s\n' "$AGENT" > "$tmp"
if [[ -f $agent_file ]]; then chmod --reference="$agent_file" "$tmp"; fi
mv -f -- "$tmp" "$agent_file"
printf 'Installed and selected %s. Authenticate when you first use it, after setup.\n' "$AGENT"
