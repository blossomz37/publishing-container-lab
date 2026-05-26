# EPUB Shell Script Guide

This workspace contains a standard EPUB archive (`sample.epub`). The clean way to work on it is to split the workflow into a few small shell scripts instead of doing everything manually.

## Recommended Script Order

1. `unpack-epub.sh`
2. `apply-edits.sh` or manual edits in the unpacked folder
3. `repack-epub.sh`
4. `validate-epub.sh`

## 1) `unpack-epub.sh`

Purpose: expand the EPUB into a normal folder tree so the XHTML, CSS, and OPF files can be edited like regular text files.

Expected job:

- Create a clean output folder, such as `unpacked/epub/vellum/` (or `unpacked/epub/affinity/`).
- Unzip the EPUB into that folder.
- Leave the archive structure intact.

Typical command shape:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT_EPUB="originals/vellum/feature-generate-book/Winter's Magic/Kindle/Winters-Magic-Kindle.epub"
OUTPUT_DIR="unpacked/epub/vellum"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
unzip -q "$INPUT_EPUB" -d "$OUTPUT_DIR"
```

What you edit after unpacking:

- `OEBPS/Story1.xhtml` for book content
- `OEBPS/css/styles.css` for styling
- `OEBPS/toc.xhtml` for navigation
- `OEBPS/package.opf` if you add, remove, or rename files

## 2) `apply-edits.sh`

Purpose: optionally automate repeated text changes after unpacking.

Use this only if you expect the same transformation every time, such as:

- Replacing a string in XHTML files
- Injecting CSS rules
- Renaming class names
- Removing unwanted metadata

If the edits are manual, this script can be omitted. In that case, the guide is simply:

- unpack
- edit files in the folder
- repack

Example pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="unpacked/epub/affinity"

perl -0pi -e 's/old-class/new-class/g' "$TARGET_DIR/OEBPS/Story1.xhtml"
```

## 3) `repack-epub.sh`

Purpose: build a fresh EPUB from the folder tree.

This step matters because EPUB files are just ZIP archives, but the `mimetype` file must be first and must stay uncompressed.

Typical command shape:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="unpacked/epub/affinity"
OUTPUT_EPUB="repacked/epub/affinity_repacked.epub"

rm -f "$OUTPUT_EPUB"
cd "$INPUT_DIR"
zip -X0 "../$OUTPUT_EPUB" mimetype
zip -Xur9D "../$OUTPUT_EPUB" META-INF OEBPS
```

Why those flags matter:

- `-X` strips extra file attributes for a cleaner EPUB.
- `-0` stores `mimetype` without compression.
- `-u` updates the archive with the remaining files.
- `-r` includes folders recursively.
- `-9` uses high compression for the rest.
- `-D` avoids directory entries that some readers do not need.

## 4) `validate-epub.sh`

Purpose: confirm the new EPUB is structurally valid before you open it in a reader.

Typical command shape:

```bash
#!/usr/bin/env bash
set -euo pipefail

EPUB_FILE="repacked/epub/affinity_repacked.epub"
unzip -t "$EPUB_FILE"
```

Optional extra checks:

- Verify `mimetype` is the first ZIP entry.
- Confirm `META-INF/container.xml` still points to `OEBPS/package.opf`.
- Confirm all files referenced in `package.opf` still exist.

## Current Workspace Tree Snapshot

```text
affinity-formatting/
├── originals/
│   ├── affinity/
│   └── vellum/
├── unpacked/
│   └── epub/
│       ├── affinity/
│       └── vellum/
├── repacked/
│   ├── epub/
│   └── vellum/
├── reports/
│   ├── markdown-versions/
│   ├── html-versions/
│   └── logs/
├── scripts/
├── tests/
│   ├── fixtures/
│   └── outputs/
└── docs/
```

## Path Conventions (From `scripts/config.sh`)

Use `scripts/config.sh` as the single source of truth for all paths.

- `AFFINITY_SOURCE_EPUB`, `AFFINITY_SOURCE_AF`: source files in `originals/affinity/`
- `VELLUM_SOURCE_EPUB`, `VELLUM_SOURCE_PACKAGE`: source files in `originals/vellum/`
- `AFFINITY_UNPACK_DIR`, `VELLUM_UNPACK_DIR`: unpack targets in `unpacked/epub/`
- `AFFINITY_COMPARE_INPUT`, `VELLUM_COMPARE_INPUT`: EPUB compare inputs from unpacked trees
- `VELLUM_PACKAGE_SANDBOX_DIR`, `VELLUM_COMPARE_PACKAGE`: package fixture location in `tests/fixtures/vellum`
- `VELLUM_COMPARE_TARGET`: baseline Vellum package in `originals/vellum/`
- `AFFINITY_REPACK_EPUB`, `VELLUM_REPACK_EPUB`: generated EPUB outputs in `repacked/epub/`
- `VELLUM_REPACK_PACKAGE`: generated package output in `repacked/vellum/`
- `COMPARE_REPORT`, `VELLUM_COMPARE_REPORT`: markdown reports in `reports/markdown-versions/`
- `EPUB_COMPARE_HTML_REPORT`, `VELLUM_COMPARE_HTML_REPORT`: HTML reports in `reports/html-versions/`
- `HTML_REPORT_DIR`: default HTML report directory (`reports/html-versions/`)
- `COMPARE_IGNORE_XHTML`: XHTML files intentionally ignored during normalized EPUB comparison

## Practical Editing Rules

- Do not rename or remove files in `OEBPS/` unless you also update `package.opf`.
- Keep `mimetype` present at the root of the unpacked EPUB.
- Keep the `META-INF/container.xml` path stable unless you know the EPUB packaging rules.
- Preserve embedded font files unless you intentionally want to change them.

## Best First Automation Pass

If you only want three scripts at first, make them these:

1. Unpack the EPUB.
2. Repack the EPUB.
3. Validate the EPUB.

That keeps the workflow small, reliable, and easy to debug before you automate edits.