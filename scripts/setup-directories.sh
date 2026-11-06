#!/usr/bin/env bash
# Shared directory layout. Safe to rerun; never deletes existing contents.
set -euo pipefail
mkdir -p -- "$HOME/src/default" "$HOME/dev/default" "$HOME/dev/clients"
