#!/usr/bin/env bash
# Verify plugin installation and bar placement with a fake Omarchy command.
# Never installs network code or edits the live shell configuration.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config"
export TEST_CALLS="$tmp/calls"
mkdir -p "$HOME/.config/omarchy/plugins" "$tmp/bin"

# Treat the other configured plugins as already installed.
while IFS= read -r id; do
  mkdir -p "$HOME/.config/omarchy/plugins/$id"
  jq -n --arg id "$id" '{id: $id}' > "$HOME/.config/omarchy/plugins/$id/manifest.json"
done < <(jq -r '.install[].id | select(. != "tomjagus.legacy-workspace-plus")' "$root/config/plugins.json")

cat > "$tmp/bin/omarchy" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ $# == 4 && $1 == plugin && $2 == add &&
   $3 == https://github.com/tom-jagus/legacy-workspace-plus.git && $4 == --yes ]]
printf '%s\n' "$*" >> "$TEST_CALLS"
target="$HOME/.config/omarchy/plugins/tomjagus.legacy-workspace-plus"
mkdir -p "$target"
printf '%s\n' '{"id":"tomjagus.legacy-workspace-plus"}' > "$target/manifest.json"
MOCK
chmod +x "$tmp/bin/omarchy"
export PATH="$tmp/bin:$PATH"
bash "$root/scripts/setup-plugins.sh"
bash "$root/scripts/setup-plugins.sh"
[[ $(wc -l < "$TEST_CALLS") == 1 ]]

shell="$HOME/.config/omarchy/shell.json"
printf '%s\n' '{"idle":{"lock":300},"bar":{"layout":{"left":[{"id":"omarchy.workspaces"}]}}}' > "$shell"
bash "$root/scripts/apply-shell-overrides.sh" "$shell"
jq -e '
  .idle.lock == 300 and
  any(.bar.layout.left[]; .id == "tomjagus.legacy-workspace-plus") and
  ([.. | objects | .id?] | index("omarchy.workspaces") == null)
' "$shell" >/dev/null
cp -- "$shell" "$tmp/merged"
bash "$root/scripts/apply-shell-overrides.sh" "$shell"
cmp -- "$shell" "$tmp/merged"
printf '%s\n' 'Workspace plugin regression checks passed.'
