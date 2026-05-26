#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

input_dir="${1:-$VELLUM_PACKAGE_SANDBOX_DIR}"
output_package="${2:-$VELLUM_REPACK_PACKAGE}"

case "$output_package" in
	/*) output_path="$output_package" ;;
	*) output_path="$PWD/$output_package" ;;
esac

output_dir="$(dirname "$output_path")"
mkdir -p "$output_dir"

pushd "$input_dir" >/dev/null
find . -type f ! -name '.DS_Store' | sed 's|^./||' | sort | zip -X -9 -@ "$output_path" >/dev/null
popd >/dev/null
