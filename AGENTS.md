# Agent Instructions

This file is the operating contract for AI agents working in this repository. Read it before making changes.

## Mission

`publishing-container-lab` is a sandbox for studying publishing containers and app-generated publishing formats. The goal is to learn how each format is structured, whether it can be unpacked and repacked safely, and what can be extracted or transformed for publishing workflows.

Current focus areas include:

- EPUB round-trip workflows
- Affinity EPUB and `.af` exports
- Vellum EPUB and `.vellum` packages
- report generation for format comparisons
- reusable scripts for container inspection, unpacking, repacking, validation, and comparison

This is an exploration repo, not a production app. Preserve evidence, document findings, and keep experiments reproducible.

## Source-Of-Truth Order

Use these files in this order when orienting yourself:

1. `AGENTS.md` for agent behavior and repo rules.
2. `README.md` for human-facing project overview.
3. `docs/LESSONS_LEARNED.md` for confirmed findings and failed assumptions.
4. `scripts/config.sh` for default paths used by scripts.
5. Format-specific docs in `docs/` for current mapping and workflow notes.

If these documents conflict, follow `AGENTS.md` and update the stale document as part of the same task when appropriate.

## Workspace Map

- `originals/`: source input files. Treat these as baselines.
- `unpacked/`: expanded container contents for inspection and editing.
- `repacked/`: generated outputs from round-trip experiments.
- `reports/`: generated markdown, HTML, and log outputs.
- `scripts/`: stable or stabilizing automation entrypoints.
- `utils/`: reusable helper code shared by scripts.
- `tests/`: fixtures and test outputs.
- `docs/`: durable notes, guides, mappings, and findings.

Do not edit source files in `originals/` unless the user explicitly asks for that. Run experiments against copies, unpacked trees, fixtures, or temporary directories.

## Core Rules

- Keep the repository portable. Do not hardcode absolute paths.
- Prefer relative paths from the repo root or configurable environment variables.
- Keep stable paths and options in config files, usually `scripts/config.sh`.
- Test scripts before describing them as working.
- Record confirmed successes and failures in `docs/LESSONS_LEARNED.md`.
- Prefer existing libraries and command-line tools before writing custom parsers.
- Keep utility functions in `utils/` once logic is shared by more than one script.
- Keep docs human-readable. Put agent-only instructions in this file, not in `README.md`.
- Preserve source artifacts and generated evidence unless cleanup is explicitly requested.

## Experiment Workflow

For any format investigation:

1. Identify the file using `file`, magic bytes, archive listing tools, or documented format metadata.
2. Avoid assuming an extension tells the truth.
3. Try non-destructive inspection before unpacking or converting.
4. If the file is archive-like, unpack to `unpacked/`, `tests/fixtures/`, or a temporary directory.
5. Make the smallest useful change or comparison.
6. Repack into `repacked/` or a temporary output path.
7. Validate with the strongest available tool.
8. Document the result in `docs/LESSONS_LEARNED.md`.

When a test fails, do not paper over it. Re-evaluate the assumption, adjust the approach, and record the failure if it taught us something.

## Script Standards

Scripts should be boring, portable, and testable.

- Use `#!/usr/bin/env bash` and `set -euo pipefail` for Bash scripts.
- Source `scripts/config.sh` for default workspace paths.
- Accept positional arguments when useful so scripts can run against temporary inputs and outputs.
- Create output directories as needed.
- Avoid local machine paths, user-specific paths, and hidden dependencies.
- Avoid writing destructive cleanup into scripts unless scoped to a generated output directory.
- Keep repeated logic in `utils/` instead of duplicating it across scripts.

Before committing script changes, run at least:

```bash
bash -n scripts/*.sh
```

Also run the changed script against a temporary output path when possible, so normal workspace reports and fixtures are not accidentally overwritten.

## EPUB Rules

EPUB files are ZIP-based, but they have packaging rules.

- Keep `mimetype` at the archive root.
- Store `mimetype` first and uncompressed when repacking.
- Preserve `META-INF/container.xml` unless deliberately testing package structure changes.
- If files are added, removed, or renamed under `OEBPS/`, update the OPF package file.
- Validate repacked EPUBs at minimum with `unzip -t`.
- Treat `unzip -t` as ZIP integrity validation only; it is not a full EPUB validator.

Use `docs/EPUB_SCRIPT_GUIDE.md` and `docs/EPUB_MAPPING.md` for current EPUB workflow and mapping notes.

## Vellum Rules

Vellum `.vellum` packages in this workspace are ZIP-readable, but still treat them as app-owned packages.

- Use `tests/fixtures/vellum/` or a temporary directory as the unpacking sandbox.
- Do not edit source packages in `originals/vellum/` directly.
- Exclude `.DS_Store` and other machine metadata from repacked packages.
- Compare package contents before claiming a round trip is clean.
- Preserve plist, `.vellumcontent`, and image folder structure unless testing a specific hypothesis.

## Affinity Rules

The Affinity EPUB sample is ZIP-readable as an EPUB. The Affinity `.af` sample is currently opaque.

- Treat `originals/affinity/sample.epub` as a normal EPUB container.
- Treat `originals/affinity/sample-epub.af` as proprietary data unless future research proves otherwise.
- Do not invent an `.af` parser from guesses. Research existing tools or documentation first.

## Documentation Rules

Use docs as durable project memory.

- Put confirmed findings, failed assumptions, and test outcomes in `docs/LESSONS_LEARNED.md`.
- Put human-facing workflow explanation in `README.md` or focused docs under `docs/`.
- Keep generated report output in `reports/`.
- When adding a new script, document its command and defaults in `scripts/README.md`.
- When a workflow becomes stable, cross-link it from the relevant guide.

Avoid vague claims like "works" or "failed" without saying what command or artifact proved it.

## Research Rules

Research knowledge gaps before deep experiments when:

- a format is proprietary or poorly understood
- a command could corrupt source artifacts
- an existing open-source project may already solve the problem
- a current standard or tool behavior may have changed

Prefer primary sources, official docs, format specs, and maintained open-source projects. Record useful references in the relevant doc when they affect the workflow.

## Git And Checkpoints

Commit after each logical unit of work.

Suggested commit message forms:

- `Add [feature]`
- `Fix [issue]`
- `Update [file]`
- `Refactor [component]`
- `Document [finding]`

Do not commit unrelated user changes. If the working tree contains changes you did not make, leave them alone unless the user asks you to include them.

## Stop Conditions

Pause and ask the user before:

- deleting source artifacts
- rewriting repository structure
- replacing sample files in `originals/`
- force-pushing or rewriting git history
- making assumptions about opaque proprietary formats
- adding heavyweight dependencies
- changing the repo's public synchronization strategy

The intended remote is `https://github.com/blossomz37/publishing-container-lab`, but do not push unless the user asks.
