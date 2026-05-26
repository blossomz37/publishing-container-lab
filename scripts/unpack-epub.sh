#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

input_epub="${1:-$VELLUM_SOURCE_EPUB}"
output_dir="${2:-$VELLUM_UNPACK_DIR}"

rm -rf "$output_dir"
mkdir -p "$output_dir"
unzip -q "$input_epub" -d "$output_dir"
