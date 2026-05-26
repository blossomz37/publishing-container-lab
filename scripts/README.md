# Scripts

This folder contains a small EPUB round-trip workflow.

The paths and output names live in [config.sh](config.sh), so you can change them in one place.

## Workspace Layout

- `originals/`: source input files (`.epub`, `.af`, `.vellum`, and Vellum export artifacts)
- `unpacked/`: unpacked working trees (`unpacked/epub/affinity`, `unpacked/epub/vellum`)
- `repacked/`: generated repacked outputs (`repacked/epub`, `repacked/vellum`)
- `reports/`: markdown and HTML comparison reports
- `tests/fixtures/`: Vellum package sandbox for mutation/testing
- `tests/outputs/`: test run outputs
- `scripts/`: automation entrypoints
- `docs/`: workflow and mapping guides

## Usage

Unpack the default source EPUB (Vellum by default):

```bash
bash scripts/unpack-epub.sh
```

Repack the unpacked EPUB:

```bash
bash scripts/repack-epub.sh
```

Validate the repacked EPUB:

```bash
bash scripts/validate-epub.sh
```

Compare the Affinity and Vellum EPUBs:

```bash
bash scripts/compare-epubs.sh
```

Export the EPUB markdown report to HTML:

```bash
bash scripts/export-epub-report-html.sh
```

One-step EPUB compare + HTML export:

```bash
bash scripts/compare-epubs.sh && bash scripts/export-epub-report-html.sh
```

By default the comparison script reads the unpacked folders already in this workspace, and it will also accept EPUB files if you pass them in explicitly.

Unpack the Vellum package into the sandbox fixture:

```bash
bash scripts/unpack-vellum.sh
```

Repack the Vellum package from the sandbox:

```bash
bash scripts/repack-vellum.sh
```

Compare the sandboxed Vellum package against another `.vellum` export:

```bash
bash scripts/compare-vellum.sh
```

Markdown report output defaults to `reports/markdown-versions/`.

HTML scaffolds and future HTML report exports default to `reports/html-versions/`.

Export the Vellum markdown report to HTML:

```bash
bash scripts/export-vellum-report-html.sh
```

One-step compare + HTML export:

```bash
bash scripts/compare-vellum.sh && bash scripts/export-vellum-report-html.sh
```

Each script accepts optional positional arguments if you want to override the default file or folder names.