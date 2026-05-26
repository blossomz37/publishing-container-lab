#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

input_dir="${1:-$VELLUM_UNPACK_DIR}"
output_epub="${2:-$VELLUM_REPACK_EPUB}"

case "$output_epub" in
	/*) output_path="$output_epub" ;;
	*) output_path="$PWD/$output_epub" ;;
esac

output_dir="$(dirname "$output_path")"

mkdir -p "$output_dir"

pushd "$input_dir" >/dev/null
zip -X0 "$output_path" mimetype >/dev/null
zip -Xur9D "$output_path" META-INF OEBPS >/dev/null
popd >/dev/null
