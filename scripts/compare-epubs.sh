#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

left_epub="${1:-$AFFINITY_COMPARE_INPUT}"
right_epub="${2:-$VELLUM_COMPARE_INPUT}"
report_path="${3:-$COMPARE_REPORT}"

resolve_input_dir() {
	local input_path="$1"
	local temp_dir="${2:-}"

	if [[ -d "$input_path" ]]; then
		printf '%s\n' "$input_path"
		return 0
	fi

	if [[ -f "$input_path" ]]; then
		if [[ -z "$temp_dir" ]]; then
			return 1
		fi
		mkdir -p "$temp_dir"
		unzip -q "$input_path" -d "$temp_dir"
		printf '%s\n' "$temp_dir"
		return 0
	fi

	return 1
}

is_ignored_xhtml() {
	local file_name="$1"
	local ignored_name
	for ignored_name in "${COMPARE_IGNORE_XHTML[@]}"; do
		if [[ "$file_name" == "$ignored_name" ]]; then
			return 0
		fi
	done
	return 1
}

normalize_xhtml_tree() {
	local input_dir="$1"
	local output_file="$2"
	: > "$output_file"
	while IFS= read -r xhtml_file; do
		local relative_path="${xhtml_file#"$input_dir"/}"
		local file_name="$(basename "$xhtml_file")"
		if is_ignored_xhtml "$file_name"; then
			continue
		fi
		{
			printf '### %s\n' "$relative_path"
			perl -0777 -pe 's{<script\b.*?</script>}{}sg; s{<style\b.*?</style>}{}sg; s{<[^>]+>}{}g; s{\s+}{ }g; s{^\s+|\s+$}{}g' "$xhtml_file"
			printf '\n\n'
		} >> "$output_file"
	done < <(find "$input_dir/OEBPS" -type f -name '*.xhtml' | sort)
}

normalize_css_tree() {
	local input_dir="$1"
	local output_file="$2"
	: > "$output_file"
	while IFS= read -r css_file; do
		perl -0777 -pe 's{/\*.*?\*/}{}sg; s{\s+}{ }g; s{^\s+|\s+$}{}g' "$css_file" >> "$output_file"
		printf '\n' >> "$output_file"
	done < <(find "$input_dir/OEBPS" -type f -name '*.css' | sort)
}

temp_root="$(mktemp -d)"
trap 'rm -rf "$temp_root"' EXIT

left_dir="$(resolve_input_dir "$left_epub" "$temp_root/left")"
right_dir="$(resolve_input_dir "$right_epub" "$temp_root/right")"

left_list="$temp_root/left-files.txt"
right_list="$temp_root/right-files.txt"

find "$left_dir" -type f | sed "s|^$left_dir/||" | sort > "$left_list"
find "$right_dir" -type f | sed "s|^$right_dir/||" | sort > "$right_list"

common_files="$temp_root/common-files.txt"
left_only="$temp_root/left-only.txt"
right_only="$temp_root/right-only.txt"

comm -12 "$left_list" "$right_list" > "$common_files"
comm -23 "$left_list" "$right_list" > "$left_only"
comm -13 "$left_list" "$right_list" > "$right_only"

left_xhtml_normalized="$temp_root/left.xhtml.normalized.txt"
right_xhtml_normalized="$temp_root/right.xhtml.normalized.txt"
left_css_normalized="$temp_root/left.css.normalized.txt"
right_css_normalized="$temp_root/right.css.normalized.txt"

normalize_xhtml_tree "$left_dir" "$left_xhtml_normalized"
normalize_xhtml_tree "$right_dir" "$right_xhtml_normalized"
normalize_css_tree "$left_dir" "$left_css_normalized"
normalize_css_tree "$right_dir" "$right_css_normalized"

content_diff="$temp_root/content.diff"
css_diff="$temp_root/css.diff"

if ! diff -u "$left_xhtml_normalized" "$right_xhtml_normalized" > "$content_diff"; then
	content_changed=1
else
	content_changed=0
fi

if ! diff -u "$left_css_normalized" "$right_css_normalized" > "$css_diff"; then
	css_changed=1
else
	css_changed=0
fi

{
	echo "# EPUB Comparison Report"
	echo
	echo "Left:  $left_epub"
	echo "Right: $right_epub"
	echo
	echo "## What This Comparison Ignores"
	echo "- META-INF package metadata"
	echo "- manifest/opf file naming differences"
	echo "- fonts, images, and other binary assets"
	echo "- navigation-only XHTML such as toc.xhtml"
	echo
	echo "## Content Comparison"
	if [[ "$content_changed" -eq 0 ]]; then
		echo "(no normalized XHTML content differences)"
	else
		sed -n '1,200p' "$content_diff"
	fi
	echo
	echo "## Stylesheet Comparison"
	if [[ "$css_changed" -eq 0 ]]; then
		echo "(no normalized CSS differences)"
	else
		sed -n '1,200p' "$css_diff"
	fi
	echo
	echo "## Input Summary"
	echo "Left source files:  $(find "$left_dir/OEBPS" -type f | wc -l | tr -d ' ')"
	echo "Right source files: $(find "$right_dir/OEBPS" -type f | wc -l | tr -d ' ')"
	echo "Ignored by path:    toc.xhtml"
} > "$report_path"

cat "$report_path"