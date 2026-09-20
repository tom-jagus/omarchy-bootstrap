#!/usr/bin/env bash
# Shared directory layout. Safe to rerun; never deletes existing contents.
set -euo pipefail
mkdir -p -- "$HOME/src/personal" "$HOME/dev/personal" "$HOME/dev/clients"
