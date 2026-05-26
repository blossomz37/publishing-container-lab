# EPUB Comparison Report

Left: `unpacked/epub/affinity`

Right: `unpacked/epub/vellum`

## What This Comparison Ignores

- `META-INF` package metadata
- manifest/OPF file naming differences
- fonts, images, and other binary assets
- navigation-only XHTML such as `toc.xhtml`

## Content Comparison

The raw normalized diff is too long to be useful in GitHub. This report summarizes the meaningful comparison points instead of pasting the full text of each XHTML file.

<details>
<summary>First content comparison: left <code>OEBPS/Story1.xhtml</code> vs right <code>OEBPS/chapter-001.xhtml</code></summary>

| Area | Left EPUB | Right EPUB |
|---|---|---|
| File compared | `OEBPS/Story1.xhtml` | `OEBPS/chapter-001.xhtml` |
| Diff marker | `-### OEBPS/Story1.xhtml` | `+### OEBPS/chapter-001.xhtml` |
| File role | Single primary story/content XHTML file | First chapter XHTML file in a multi-file book structure |
| Opening/title signal | "How to Create an Affinity EPUB with a Custom CSS File for Amazon and Kindle How to Create an Aff" | "Chapter 1: The Fading Enchantment 1 THE FADING ENCHANTMENT As the winter evening settled over Se" |
| Structure signal | Left sample keeps its first comparable content in one XHTML file | Right sample begins with a chapter file and may split book matter across more XHTML files |
| Mapping implication | Compare this as a source-structure sample, not as guaranteed matching book text | Use this as the first chapter/sample file when studying the right EPUB structure |

</details>

<details>
<summary>Right-only XHTML files added in the normalized comparison</summary>

| Right XHTML file | Role in the export |
|---|---|
| `OEBPS/chapter-001.xhtml` | First chapter XHTML file in a multi-file book structure |
| `OEBPS/chapter-002.xhtml` | Chapter body matter |
| `OEBPS/chapter-003.xhtml` | Chapter body matter |
| `OEBPS/chapter-004.xhtml` | Chapter body matter |
| `OEBPS/chapter-005.xhtml` | Chapter body matter |
| `OEBPS/contents.xhtml` | Contents/front matter |
| `OEBPS/copyright.xhtml` | Copyright/front matter |
| `OEBPS/title-page.xhtml` | Title page/front matter |

</details>

## Stylesheet Comparison

<details>
<summary>High-level stylesheet differences</summary>

| Area | Left EPUB | Right EPUB |
|---|---|---|
| Stylesheet layout | `OEBPS/css/styles.css` | `OEBPS/css/media.css, OEBPS/css/style.css` |
| Selector style | Generated classes from source document styles | Generated semantic-ish classes and media-targeted rules |
| Body text model | Style classes carry much of the formatting intent | Element selectors and semantic classes carry much of the formatting intent |
| Mapping implication | Map styling intent, not class names | Rebuild equivalent typography in the target structure instead of copying CSS directly |

</details>

## Input Summary

| Metric | Count / Value |
|---|---:|
| Left source files | 7 |
| Right source files | 22 |
| Ignored by path | `toc.xhtml` |
