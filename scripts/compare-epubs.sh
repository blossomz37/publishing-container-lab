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

escape_markdown_cell() {
	local value="$1"
	value="${value//$'\n'/ }"
	value="${value//|/\\|}"
	printf '%s' "$value"
}

first_xhtml_file() {
	local input_dir="$1"
	while IFS= read -r xhtml_file; do
		local file_name
		file_name="$(basename "$xhtml_file")"
		if is_ignored_xhtml "$file_name"; then
			continue
		fi
		printf '%s\n' "$xhtml_file"
		return 0
	done < <(find "$input_dir/OEBPS" -type f -name '*.xhtml' | sort)
	return 1
}

relative_to_input() {
	local input_dir="$1"
	local path="$2"
	printf '%s\n' "${path#"$input_dir"/}"
}

xhtml_snippet() {
	local xhtml_file="$1"
	perl -0777 -pe 's{<script\b.*?</script>}{}sg; s{<style\b.*?</style>}{}sg; s{<[^>]+>}{}g; s{\s+}{ }g; s{^\s+|\s+$}{}g' "$xhtml_file" |
		cut -c 1-96 |
		sed 's/[[:space:]]*$//'
}

xhtml_role() {
	local relative_path="$1"
	case "$relative_path" in
		*Story*.xhtml)
			printf 'Single primary story/content XHTML file'
			;;
		*chapter-001.xhtml)
			printf 'First chapter XHTML file in a multi-file book structure'
			;;
		*chapter-*.xhtml)
			printf 'Chapter body matter'
			;;
		*contents.xhtml)
			printf 'Contents/front matter'
			;;
		*copyright.xhtml)
			printf 'Copyright/front matter'
			;;
		*title-page.xhtml)
			printf 'Title page/front matter'
			;;
		*)
			printf 'XHTML content file'
			;;
	esac
}

left_first_xhtml="$(first_xhtml_file "$left_dir" || true)"
right_first_xhtml="$(first_xhtml_file "$right_dir" || true)"
left_first_relative=""
right_first_relative=""
left_first_snippet=""
right_first_snippet=""
left_first_role="No comparable XHTML file found"
right_first_role="No comparable XHTML file found"

if [[ -n "$left_first_xhtml" ]]; then
	left_first_relative="$(relative_to_input "$left_dir" "$left_first_xhtml")"
	left_first_snippet="$(xhtml_snippet "$left_first_xhtml")"
	left_first_role="$(xhtml_role "$left_first_relative")"
fi

if [[ -n "$right_first_xhtml" ]]; then
	right_first_relative="$(relative_to_input "$right_dir" "$right_first_xhtml")"
	right_first_snippet="$(xhtml_snippet "$right_first_xhtml")"
	right_first_role="$(xhtml_role "$right_first_relative")"
fi

right_only_xhtml="$temp_root/right-only-xhtml.txt"
while IFS= read -r relative_path; do
	case "$relative_path" in
		OEBPS/*.xhtml)
			local_name="$(basename "$relative_path")"
			if is_ignored_xhtml "$local_name"; then
				continue
			fi
			printf '%s\n' "$relative_path"
			;;
	esac
done < "$right_only" > "$right_only_xhtml"

left_css_files="$(find "$left_dir/OEBPS" -type f -name '*.css' | sed "s|^$left_dir/||" | sort | paste -sd ',' - | sed 's/,/, /g')"
right_css_files="$(find "$right_dir/OEBPS" -type f -name '*.css' | sed "s|^$right_dir/||" | sort | paste -sd ',' - | sed 's/,/, /g')"
left_source_file_count="$(find "$left_dir/OEBPS" -type f ! -name '.gitkeep' | wc -l | tr -d ' ')"
right_source_file_count="$(find "$right_dir/OEBPS" -type f ! -name '.gitkeep' | wc -l | tr -d ' ')"

{
	echo "# EPUB Comparison Report"
	echo
	echo "Left: \`$left_epub\`"
	echo
	echo "Right: \`$right_epub\`"
	echo
	echo "## What This Comparison Ignores"
	echo
	echo "- \`META-INF\` package metadata"
	echo "- manifest/OPF file naming differences"
	echo "- fonts, images, and other binary assets"
	echo "- navigation-only XHTML such as \`toc.xhtml\`"
	echo
	echo "## Content Comparison"
	echo
	if [[ "$content_changed" -eq 0 ]]; then
		echo "(no normalized XHTML content differences)"
	else
		echo "The raw normalized diff is too long to be useful in GitHub. This report summarizes the meaningful comparison points instead of pasting the full text of each XHTML file."
		echo
		echo "<details>"
		echo "<summary>First content comparison: left <code>${left_first_relative:-none}</code> vs right <code>${right_first_relative:-none}</code></summary>"
		echo
		echo "| Area | Left EPUB | Right EPUB |"
		echo "|---|---|---|"
		echo "| File compared | \`$(escape_markdown_cell "${left_first_relative:-none}")\` | \`$(escape_markdown_cell "${right_first_relative:-none}")\` |"
		echo "| Diff marker | \`-### $(escape_markdown_cell "${left_first_relative:-none}")\` | \`+### $(escape_markdown_cell "${right_first_relative:-none}")\` |"
		echo "| File role | $(escape_markdown_cell "$left_first_role") | $(escape_markdown_cell "$right_first_role") |"
		echo "| Opening/title signal | \"$(escape_markdown_cell "$left_first_snippet")\" | \"$(escape_markdown_cell "$right_first_snippet")\" |"
		echo "| Structure signal | Left sample keeps its first comparable content in one XHTML file | Right sample begins with a chapter file and may split book matter across more XHTML files |"
		echo "| Mapping implication | Compare this as a source-structure sample, not as guaranteed matching book text | Use this as the first chapter/sample file when studying the right EPUB structure |"
		echo
		echo "</details>"
		echo
		if [[ -s "$right_only_xhtml" ]]; then
			echo "<details>"
			echo "<summary>Right-only XHTML files added in the normalized comparison</summary>"
			echo
			echo "| Right XHTML file | Role in the export |"
			echo "|---|---|"
			while IFS= read -r relative_path; do
				echo "| \`$(escape_markdown_cell "$relative_path")\` | $(escape_markdown_cell "$(xhtml_role "$relative_path")") |"
			done < "$right_only_xhtml"
			echo
			echo "</details>"
		fi
	fi
	echo
	echo "## Stylesheet Comparison"
	echo
	if [[ "$css_changed" -eq 0 ]]; then
		echo "(no normalized CSS differences)"
	else
		echo "<details>"
		echo "<summary>High-level stylesheet differences</summary>"
		echo
		echo "| Area | Left EPUB | Right EPUB |"
		echo "|---|---|---|"
		echo "| Stylesheet layout | \`$(escape_markdown_cell "$left_css_files")\` | \`$(escape_markdown_cell "$right_css_files")\` |"
		echo "| Selector style | Generated classes from source document styles | Generated semantic-ish classes and media-targeted rules |"
		echo "| Body text model | Style classes carry much of the formatting intent | Element selectors and semantic classes carry much of the formatting intent |"
		echo "| Mapping implication | Map styling intent, not class names | Rebuild equivalent typography in the target structure instead of copying CSS directly |"
		echo
		echo "</details>"
	fi
	echo
	echo "## Input Summary"
	echo
	echo "| Metric | Count / Value |"
	echo "|---|---:|"
	echo "| Left source files | $left_source_file_count |"
	echo "| Right source files | $right_source_file_count |"
	echo "| Ignored by path | \`toc.xhtml\` |"
} > "$report_path"

cat "$report_path"
