#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

epub_file="${1:-$VELLUM_REPACK_EPUB}"
unzip -t "$epub_file"
