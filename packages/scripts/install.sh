#!/usr/bin/env bash
# --list-packages validates all lists and prints packages without installing.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $# == 0 || ( $# == 1 && $1 == --list-packages ) ]] || {
  echo 'Usage: install.sh [--list-packages]' >&2; exit 1;
}
methods=()
packages=()

# Read and validate all input before any installation.
for method in repo aur; do
  while read -r package extra || [[ -n $package ]]; do
    [[ -z $package || $package == \#* ]] && continue
    [[ -z $extra && $package =~ ^[a-zA-Z0-9][a-zA-Z0-9@._+-]*$ ]] || {
      echo "Invalid package in $method-install: $package $extra" >&2; exit 1;
    }
    methods+=("$method")
    packages+=("$package")
  done < "$script_dir/../$method-install"
done

while read -r -a args; do
  (( ${#args[@]} )) || continue
  [[ ${args[0]} == \#* ]] && continue
  # Explicitly supported commands provide reliable completion checks. Never
  # eval this file. Add a mapping here when introducing another installer.
  case "${args[*]}" in
    'install service signal') method=signal; package=signal-desktop ;;
    'install ai chatgpt') method=chatgpt; package=openai-codex-desktop ;;
    *) echo "Unsupported Omarchy installer: ${args[*]}" >&2; exit 1 ;;
  esac
  methods+=("$method")
  packages+=("$package")
done < "$script_dir/../omarchy-install"

if [[ ${1:-} == --list-packages ]]; then
  if (( ${#packages[@]} )); then printf '%s\n' "${packages[@]}"; fi
  exit 0
fi

for i in "${!packages[@]}"; do
  package=${packages[$i]}
  if pacman -Q "$package" >/dev/null 2>&1; then
    echo "Already installed: $package"
    continue
  fi
  case "${methods[$i]}" in
    repo) omarchy pkg add "$package" ;;
    aur) omarchy pkg aur add "$package" ;;
    signal) omarchy install service signal ;;
    chatgpt) omarchy install ai chatgpt ;;
  esac
  pacman -Q "$package" >/dev/null || { echo "Installation failed: $package" >&2; exit 1; }
done
