#!/usr/bin/env bash

# Source of truth for EPUB file locations and unpack/repack targets.
# Edit this file instead of hardcoding paths inside the scripts.

AFFINITY_SOURCE_EPUB="originals/affinity/sample.epub"
AFFINITY_SOURCE_AF="originals/affinity/sample-epub.af"
VELLUM_SOURCE_EPUB="originals/vellum/feature-generate-book/Winter's Magic/Kindle/Winters-Magic-Kindle.epub"
VELLUM_SOURCE_PACKAGE="originals/vellum/Winter's Magic_marisol-reyes.vellum"

AFFINITY_UNPACK_DIR="unpacked/epub/affinity"
VELLUM_UNPACK_DIR="unpacked/epub/vellum"
VELLUM_PACKAGE_SANDBOX_DIR="tests/fixtures/vellum"

AFFINITY_COMPARE_INPUT="unpacked/epub/affinity"
VELLUM_COMPARE_INPUT="unpacked/epub/vellum"
VELLUM_COMPARE_PACKAGE="tests/fixtures/vellum"
VELLUM_COMPARE_TARGET="originals/vellum/Winter's Magic_marisol-reyes.vellum"

AFFINITY_REPACK_EPUB="repacked/epub/affinity_repacked.epub"
VELLUM_REPACK_EPUB="repacked/epub/vellum_repacked.epub"
VELLUM_REPACK_PACKAGE="repacked/vellum/Winter's Magic_marisol-reyes-repacked.vellum"

COMPARE_REPORT="reports/markdown-versions/epub_compare_report.md"
EPUB_COMPARE_HTML_REPORT="reports/html-versions/epub_compare_report.html"
VELLUM_COMPARE_REPORT="reports/markdown-versions/vellum_compare_report.md"
HTML_REPORT_DIR="reports/html-versions"
VELLUM_COMPARE_HTML_REPORT="reports/html-versions/vellum_compare_report.html"

COMPARE_IGNORE_XHTML=("toc.xhtml")
