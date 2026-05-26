#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

input_package="${1:-$VELLUM_SOURCE_PACKAGE}"
output_dir="${2:-$VELLUM_PACKAGE_SANDBOX_DIR}"

rm -rf "$output_dir"
mkdir -p "$output_dir"
unzip -q "$input_package" -d "$output_dir"
