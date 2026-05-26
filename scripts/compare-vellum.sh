#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

left_input="${1:-$VELLUM_COMPARE_PACKAGE}"
right_input="${2:-$VELLUM_COMPARE_TARGET}"
report_path="${3:-$VELLUM_COMPARE_REPORT}"

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

temp_root="$(mktemp -d)"
trap 'rm -rf "$temp_root"' EXIT

left_dir="$(resolve_input_dir "$left_input" "$temp_root/left")"
right_dir="$(resolve_input_dir "$right_input" "$temp_root/right")"

left_list="$temp_root/left-files.txt"
right_list="$temp_root/right-files.txt"
find "$left_dir" -type f ! -name '.gitkeep' ! -name '.DS_Store' | sed "s|^$left_dir/||" | sort > "$left_list"
find "$right_dir" -type f ! -name '.gitkeep' ! -name '.DS_Store' | sed "s|^$right_dir/||" | sort > "$right_list"

common_files="$temp_root/common-files.txt"
left_only="$temp_root/left-only.txt"
right_only="$temp_root/right-only.txt"
comm -12 "$left_list" "$right_list" > "$common_files"
comm -23 "$left_list" "$right_list" > "$left_only"
comm -13 "$left_list" "$right_list" > "$right_only"

changed_files="$temp_root/changed.txt"
: > "$changed_files"
plist_changed="$temp_root/plist-changed.txt"
content_changed="$temp_root/content-changed.txt"
image_changed="$temp_root/image-changed.txt"
other_changed="$temp_root/other-changed.txt"
: > "$plist_changed"
: > "$content_changed"
: > "$image_changed"
: > "$other_changed"
image_groups_dir="$temp_root/image-groups"
mkdir -p "$image_groups_dir"

mkdir -p "$(dirname "$report_path")"

classify_changed_path() {
	local relative_path="$1"

	case "$relative_path" in
		*.plist)
			printf '%s\n' "$plist_changed"
			return 0
			;;
		*.vellumcontent)
			printf '%s\n' "$content_changed"
			return 0
			;;
		images/*)
			local_image_folder="${relative_path#images/}"
			local_image_folder="${local_image_folder%%/*}"
			local_image_kind_path="${relative_path#images/$local_image_folder/}"
			local_image_kind="${local_image_kind_path%%/*}"
			mkdir -p "$image_groups_dir/$local_image_folder/$local_image_kind"
			printf '%s\n' "$relative_path" >> "$image_groups_dir/$local_image_folder/$local_image_kind/files.txt"
			printf '%s\n' "$image_changed"
			return 0
			;;
		*)
			printf '%s\n' "$other_changed"
			return 0
			;;
	esac
}

while IFS= read -r relative_path; do
	if ! cmp -s "$left_dir/$relative_path" "$right_dir/$relative_path"; then
		printf '%s\n' "$relative_path" >> "$changed_files"
		bucket_file="$(classify_changed_path "$relative_path")"
		printf '%s\n' "$relative_path" >> "$bucket_file"
	fi
done < "$common_files"

{
	echo "# Vellum Package Comparison Report"
	echo
	echo "Left:  $left_input"
	echo "Right: $right_input"
	echo
	echo "## Files only on the left"
	if [[ -s "$left_only" ]]; then
		cat "$left_only"
	else
		echo "(none)"
	fi
	echo
	echo "## Files only on the right"
	if [[ -s "$right_only" ]]; then
		cat "$right_only"
	else
		echo "(none)"
	fi
	echo
	echo "## Plist Differences"
	if [[ -s "$plist_changed" ]]; then
		cat "$plist_changed"
	else
		echo "(none)"
	fi
	echo
	echo "## Vellum Content Differences"
	if [[ -s "$content_changed" ]]; then
		cat "$content_changed"
	else
		echo "(none)"
	fi
	echo
	echo "## Binary Image Differences By Folder"
	if [[ -s "$image_changed" ]]; then
		while IFS= read -r image_group_dir; do
			image_group_name="$(basename "$(dirname "$image_group_dir")")"
			echo "### images/$image_group_name"
			for image_kind in original variant; do
				image_kind_file="$image_group_dir/$image_kind/files.txt"
				if [[ -f "$image_kind_file" ]]; then
					echo "#### $image_kind"
					cat "$image_kind_file"
					echo
				fi
			done
		done < <(find "$image_groups_dir" -mindepth 2 -maxdepth 2 -type d | sort)
	else
		echo "(none)"
	fi
	echo
	echo "## Other Differences"
	if [[ -s "$other_changed" ]]; then
		cat "$other_changed"
	else
		echo "(none)"
	fi
	echo
	echo "## Counts"
	echo "Common files: $(wc -l < "$common_files" | tr -d ' ')"
	echo "Left only:    $(wc -l < "$left_only" | tr -d ' ')"
	echo "Right only:   $(wc -l < "$right_only" | tr -d ' ')"
	echo "Plist:        $(wc -l < "$plist_changed" | tr -d ' ')"
	echo "Content:      $(wc -l < "$content_changed" | tr -d ' ')"
	echo "Images:       $(wc -l < "$image_changed" | tr -d ' ')"
	echo "Other:        $(wc -l < "$other_changed" | tr -d ' ')"
	echo
	echo "## What This Proves"
	if [[ ! -s "$left_only" && ! -s "$right_only" && ! -s "$changed_files" ]]; then
		echo "The unpacked fixture and source Vellum package contain the same file set, and every common file compares byte-for-byte identical. This confirms the current unpacked sandbox is a faithful extraction of the source package. It does not prove that edited packages will reopen in Vellum or that every future mutation is safe."
	else
		echo "This comparison found file-set or byte-level differences, so the current sandbox is not an identical extraction of the source package. Review the sections above before treating this package state as a clean baseline."
	fi
} > "$report_path"

cat "$report_path"
