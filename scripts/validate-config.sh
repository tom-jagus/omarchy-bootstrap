#!/usr/bin/env bash
# Validate all preferences before the first install or removal.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

jq -e -s 'length == 1 and (.[0] |
  type == "object" and
  (.agent as $a | ["pi", "opencode", "claude", "codex", "crush", "gemini", "copilot", "cursor-agent", "omp", "grok"] | index($a) != null) and
  (.terminal as $t | ["alacritty", "foot", "ghostty", "kitty"] | index($t) != null) and
  (.browser as $b | ["vivaldi", "chromium", "chrome", "brave", "brave-origin", "edge", "firefox", "zen"] | index($b) != null) and
  (.dictation | type == "boolean") and
  (.hypr.url | type == "string" and test("^https://github\\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+\\.git$")) and
  (.hypr.ref | type == "string" and test("^[a-zA-Z0-9][a-zA-Z0-9._/-]*$"))
)' "$root/config/defaults.json" >/dev/null

jq -e -s 'length == 1 and (.[0] |
  def names: type == "array" and all(.[]; type == "string" and test("^[a-zA-Z0-9][a-zA-Z0-9@._+-]*$"));
  (.install.repo | names) and (.install.aur | names) and (.remove | names) and
  ([.install.repo[], .install.aur[]] | length == (unique | length)) and
  ([.install.repo[], .install.aur[], .remove[]] | length == (unique | length))
)' "$root/config/packages.json" >/dev/null

jq -e -s 'length == 1 and (.[0] |
  def id: type == "string" and test("^[a-zA-Z0-9][a-zA-Z0-9._-]*$") and (contains("..") | not);
  (.install | type == "array" and all(.[]; type == "object" and
    (.id | id) and (.url | type == "string" and test("^https://github\\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+\\.git$")))) and
  (.remove | type == "array" and all(.[]; id)) and
  ([.install[].id, .remove[]] | length == (unique | length))
)' "$root/config/plugins.json" >/dev/null

jq -e -s 'length == 1 and (.[0] |
  def name: type == "string" and length > 0 and (test("[/\\x00-\\x1f]") | not);
  (.install | type == "array" and all(.[]; type == "object" and
    (.name | name) and (.url | type == "string" and test("^https://[^[:space:]]+$")) and
    (.icon | type == "string" and test("^[a-zA-Z0-9_.-]+$")))) and
  (.remove | type == "array" and all(.[]; name)) and
  ([.install[].name, .remove[]] | length == (unique | length))
)' "$root/config/webapps.json" >/dev/null

jq -e -s 'length == 1 and (.[0] | type == "object" and
  (.bar.layout.left | type == "array" and all(.[]; type == "object" and (.id | type == "string"))) and
  (.bar.layout.center | type == "array" and all(.[]; type == "object" and (.id | type == "string"))) and
  (.bar.layout.right | type == "array" and all(.[]; type == "object" and (.id | type == "string"))) and
  (.plugins | type == "array" and all(.[]; type == "object" and (.id | type == "string"))))' "$root/config/shell-overrides.json" >/dev/null

# Never remove a plugin that the desired bar or enabled plugin list still names.
jq -e --slurpfile overrides "$root/config/shell-overrides.json" '
  all(.remove[]; . as $id | ([ $overrides[0] | .. | objects | .id? ] | index($id) == null))
' "$root/config/plugins.json" >/dev/null

terminal=$(jq -r '.terminal' "$root/config/defaults.json")
jq -e --arg terminal "$terminal" '.remove | index($terminal) == null' "$root/config/packages.json" >/dev/null
