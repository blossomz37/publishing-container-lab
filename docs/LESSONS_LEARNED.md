# Lessons Learned

Use this file for confirmed findings from experiments in this workspace. Keep speculative ideas out of here until a command, script run, report, or inspected artifact proves them.

## 2026-05-26 - Initial Lessons Learned 

### Container Identification

- `originals/affinity/sample.epub` identifies as an EPUB document and passes `unzip -t`.
- `originals/vellum/feature-generate-book/Winter's Magic/Kindle/Winters-Magic-Kindle.epub` identifies as an EPUB document and passes `unzip -t`.
- `repacked/epub/vellum_repacked.epub` identifies as an EPUB document.
- `tests/outputs/sample_roundtrip.epub` identifies as an EPUB document.
- `originals/vellum/Winter's Magic_marisol-reyes.vellum` identifies as ZIP archive data and passes `unzip -t`.
- `originals/affinity/sample-epub.af` identifies only as `data`; `unzip -t` fails with exit code 9 because no ZIP central directory is found. Treat `.af` as opaque/proprietary unless a better unpacking method is discovered.

### EPUB Round-Trip Behavior

- EPUB repacking cannot be treated as a plain recursive ZIP. The `mimetype` file must stay first in the archive and must be stored without compression.
- `scripts/repack-epub.sh` currently preserves the required first archive entry for `repacked/epub/vellum_repacked.epub`; `zipinfo -1` shows `mimetype` as the first item.
- `scripts/validate-epub.sh` currently validates by running `unzip -t`. This confirms ZIP integrity, but it is not a full EPUBCheck-style validation.
- Temporary-output testing confirmed this script chain works for the Vellum EPUB: unpack, repack, validate.

### Affinity EPUB Structure

- The Affinity EPUB unpacks into a compact structure with one primary XHTML content file: `OEBPS/Story1.xhtml`.
- The Affinity EPUB uses `OEBPS/package.opf` as the package file.
- The Affinity EPUB includes `OEBPS/toc.xhtml` for navigation.
- The Affinity EPUB uses a single main stylesheet at `OEBPS/css/styles.css`.
- The Affinity EPUB includes embedded Arial font files.
- The Affinity EPUB includes `META-INF/encryption.xml`; preserve it unless a specific experiment proves it can be changed safely.

### Vellum EPUB Structure

- The Vellum Kindle EPUB unpacks into a multi-file book structure with separate chapter files: `chapter-001.xhtml` through `chapter-005.xhtml`.
- The Vellum EPUB uses `OEBPS/content.opf` as the package file.
- The Vellum EPUB includes both `OEBPS/toc.xhtml` and `OEBPS/toc.ncx`.
- The Vellum EPUB separates styling into `OEBPS/css/style.css` and `OEBPS/css/media.css`.
- The Vellum EPUB includes title, contents, and copyright XHTML files as separate front-matter files.
- The Vellum EPUB includes embedded Cormorant fonts and the SIL Open Font License file.
- The Vellum EPUB includes image assets, including SVG assets and a cover-style JPG asset.

### Affinity vs Vellum EPUB Mapping

- The round-trip mechanics are similar for both EPUBs: unpack, edit, repack, validate.
- The internal layouts are not equivalent. Affinity currently exports a single primary story XHTML file, while Vellum splits body matter into chapter files.
- The CSS models are not equivalent. Affinity uses generated class names from document styles, while Vellum uses a more semantic generated structure plus separate media styling.
- Content intent is mappable: title, author, reading order, body text, emphasis, images, fonts, links, TOC intent, and basic metadata.
- Exact class names and generated wrapper structures are not directly mappable. Any conversion should map meaning first, then rebuild package structure and CSS.
- `docs/EPUB_MAPPING.md` is the current source for the practical crosswalk between the two exports.

### Vellum Package Behavior

- The source `.vellum` package is ZIP-readable.
- The sandbox fixture in `tests/fixtures/vellum/` currently contains the expected package-level files: plist metadata, `content.vellumcontent`, and image folders with original and variant assets.
- The current Vellum package comparison report shows no differences between `tests/fixtures/vellum` and `originals/vellum/Winter's Magic_marisol-reyes.vellum`.
- `scripts/repack-vellum.sh` excludes `.DS_Store` files when building the package. Keep doing this to avoid macOS metadata churn in generated packages.

### Reporting And Script Behavior

- Markdown reports currently live in `reports/markdown-versions/`.
- HTML reports currently live in `reports/html-versions/`.
- `scripts/compare-epubs.sh` writes a markdown report and also prints that report to stdout. This is useful for immediate inspection but noisy in test logs.
- The EPUB comparison intentionally ignores some expected differences, including navigation-only XHTML, binary assets, package metadata, and manifest naming differences.
- `scripts/export-epub-report-html.sh` and `scripts/export-vellum-report-html.sh` both successfully generated HTML from temporary markdown report outputs during validation.
- `scripts/config.sh` is the current source of truth for default paths. New scripts should keep using config values or explicit positional arguments instead of embedding local paths.

### Open Questions

- The workspace does not yet have formal automated tests that can be run without touching the working reports. Add tests before treating the scripts as stable shared tooling.
- EPUB validation currently checks ZIP integrity only. A future pass should test with an EPUB-specific validator.
- The Affinity `.af` file remains opaque. Future research should look for official Affinity export/import tooling or documented file-format work before attempting custom parsing.
- A selector-level Affinity-to-Vellum CSS crosswalk would be useful, but should be generated from the current unpacked files instead of guessed.

## 2026-05-26 - README Audit Validation

- `README.md` was rebuilt from the current workspace structure, existing docs, script behavior, and sample files.
- Shell syntax validation passed with `bash -n scripts/*.sh`.
- EPUB round-trip validation passed using temporary outputs: unpack Vellum EPUB, repack it, then validate the repacked EPUB with `unzip -t`.
- EPUB comparison and HTML export completed successfully when pointed at temporary report outputs.
- Vellum package unpack, repack, compare, and HTML export completed successfully when pointed at temporary outputs.
- The current Vellum package fixture still compares cleanly against `originals/vellum/Winter's Magic_marisol-reyes.vellum`.
- The EPUB comparison script is intentionally noisy because it prints the markdown report to stdout; use a temporary report path when testing to avoid overwriting workspace reports.

## 2026-05-26 - EPUB Report Markdown Readability

- The raw normalized XHTML/CSS diff in `reports/markdown-versions/epub_compare_report.md` was too long for practical GitHub reading.
- `scripts/compare-epubs.sh` now writes collapsed GitHub `<details>` sections with summary tables instead of dumping the first 200 raw diff lines.
- The content table focuses on the first comparable XHTML pair: `OEBPS/Story1.xhtml` vs `OEBPS/chapter-001.xhtml`.
- The report still preserves the important comparison signal: Affinity uses one primary story XHTML file, while Vellum splits the sample into chapter/front-matter XHTML files.
- Regenerating the report with `bash scripts/compare-epubs.sh unpacked/epub/affinity unpacked/epub/vellum reports/markdown-versions/epub_compare_report.md` produced the concise table format successfully.
