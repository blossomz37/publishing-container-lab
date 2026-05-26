# Publishing Container Lab

This repository is a practical lab for taking publishing files apart, studying how they work, and putting them back together again.

The current focus is EPUB and Vellum package exploration:

- unpacking EPUB files into editable folders
- comparing Affinity and Vellum EPUB exports
- repacking EPUBs in a reader-friendly ZIP structure
- validating round-trip EPUB outputs
- unpacking and repacking `.vellum` packages for safe inspection
- documenting what is portable, what is vendor-specific, and what still needs testing

This is not a polished product yet. It is a working research space for learning which publishing containers can survive round-trip edits and which parts of those formats need special handling.

## What Is In This Workspace

```text
docs/       Human-readable notes, guides, and mapping documents
originals/  Source files used for format experiments
repacked/   Generated round-trip outputs
reports/    Markdown and HTML comparison reports
scripts/    Shell scripts for unpacking, repacking, validating, and comparing
tests/      Fixtures and test outputs
unpacked/   Expanded container contents for inspection and editing
utils/      Shared helper code can live here as scripts mature
```

The important thing to remember: `originals/` should be treated as source material. Work in `unpacked/`, generate into `repacked/`, and record findings in `docs/`.

## Current Format Coverage

### EPUB

EPUB files are ZIP-based containers with packaging rules. The scripts in this repo can unpack, repack, validate, and compare EPUB exports.

Current EPUB examples include:

- an Affinity-exported EPUB in `originals/affinity/`
- a Vellum-generated Kindle EPUB in `originals/vellum/feature-generate-book/`

The two EPUBs are structurally different, so the goal is not byte-for-byte equality. The goal is to understand what content, styling, metadata, and file-layout concepts can be mapped between them.

Start with:

- [EPUB Script Guide](docs/EPUB_SCRIPT_GUIDE.md)
- [EPUB Mapping: Affinity Export vs Vellum Export](docs/EPUB_MAPPING.md)

### Vellum Packages

Vellum `.vellum` files in this workspace behave like ZIP archives. The current scripts can unpack a Vellum package into a fixture directory, compare that unpacked fixture against the source package, and repack it.

The current Vellum comparison report shows the sandbox fixture and source package matching with no content, plist, image, or other file differences.

Start with:

- [Scripts README](scripts/README.md)
- [Container Type Guide](docs/CONTAINER_TYPE_GUIDE.md)

### Affinity `.af`

The Affinity `.af` sample currently identifies as opaque data rather than a normal ZIP-style archive. Treat it as a proprietary file unless future research proves a safe unpacking path.

See:

- [Container Type Guide](docs/CONTAINER_TYPE_GUIDE.md)

## Quick Start

Run commands from the repository root.

```bash
bash scripts/unpack-epub.sh
bash scripts/repack-epub.sh
bash scripts/validate-epub.sh
```

By default, these commands use the Vellum EPUB paths defined in `scripts/config.sh`.

To compare the current Affinity and Vellum EPUB worktrees:

```bash
bash scripts/compare-epubs.sh
bash scripts/export-epub-report-html.sh
```

To compare the Vellum package fixture against the original Vellum package:

```bash
bash scripts/compare-vellum.sh
bash scripts/export-vellum-report-html.sh
```

Each script accepts optional positional arguments if you want to override the default input or output paths.

## Configuration

Path defaults live in:

```text
scripts/config.sh
```

Change that file instead of hardcoding paths inside scripts. The workspace is meant to stay portable, so avoid absolute paths. Prefer relative paths from the repository root or environment variables when a path needs to be configurable.

## Common Workflows

### Inspect An EPUB

```bash
bash scripts/unpack-epub.sh
```

Then inspect the expanded files under `unpacked/epub/vellum/` or whichever output directory you selected.

Typical files to inspect:

- `mimetype`
- `META-INF/container.xml`
- `OEBPS/content.opf` or `OEBPS/package.opf`
- `OEBPS/toc.xhtml`
- chapter `.xhtml` files
- CSS files under `OEBPS/css/`

### Repack And Validate An EPUB

```bash
bash scripts/repack-epub.sh
bash scripts/validate-epub.sh
```

EPUB repacking is sensitive to ZIP ordering. The `mimetype` file must be first and uncompressed, which is why the repack script does more than a plain `zip -r`.

### Generate Comparison Reports

```bash
bash scripts/compare-epubs.sh
bash scripts/export-epub-report-html.sh
```

Reports are written to:

```text
reports/markdown-versions/
reports/html-versions/
```

The EPUB comparison intentionally ignores some expected differences, including navigation-only XHTML, binary assets, and package metadata noise. The purpose is to highlight meaningful structural and content differences, not every generated file detail.

### Work With A Vellum Package

```bash
bash scripts/unpack-vellum.sh
bash scripts/compare-vellum.sh
bash scripts/repack-vellum.sh
```

Use `tests/fixtures/vellum/` as the sandbox for unpacked package contents. Do not edit the source `.vellum` file directly.

## Repository Rules Of Thumb

- Keep `originals/` as source inputs.
- Put repeatable automation in `scripts/`.
- Put reusable helper logic in `utils/` when scripts start sharing behavior.
- Keep configurable paths in config files.
- Write findings in `docs/`, especially when an assumption succeeds or fails.
- Test scripts before treating them as stable.
- Prefer existing format libraries and command-line tools before writing custom parsers.
- Do not hardcode absolute local paths.

## Useful Docs

- [Container Type Guide](docs/CONTAINER_TYPE_GUIDE.md): how to identify whether a file is ZIP-like, proprietary, or opaque
- [EPUB Script Guide](docs/EPUB_SCRIPT_GUIDE.md): the current EPUB round-trip workflow
- [EPUB Mapping](docs/EPUB_MAPPING.md): what maps between Affinity and Vellum EPUB exports
- [Scripts README](scripts/README.md): script-level command reference
- [Lessons Learned](docs/LESSONS_LEARNED.md): place to record confirmed discoveries and failed assumptions

## Current Status

The lab currently has working shell scripts for:

- unpacking EPUB files
- repacking EPUB files
- validating repacked EPUB files with `unzip -t`
- comparing Affinity and Vellum EPUB structures
- exporting EPUB comparison reports to HTML
- unpacking Vellum packages
- repacking Vellum packages
- comparing Vellum package contents
- exporting Vellum package comparison reports to HTML

The next useful improvements are likely:

- add script-level tests that can run without overwriting workspace reports
- move repeated comparison helper logic into `utils/`
- add a selector crosswalk for Affinity CSS classes and Vellum semantic equivalents
- expand `docs/LESSONS_LEARNED.md` as experiments produce confirmed findings
