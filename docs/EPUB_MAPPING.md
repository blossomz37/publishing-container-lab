# EPUB Mapping: Affinity Export vs Vellum Export

This guide answers what can be mapped between the Affinity EPUB export and the Vellum Kindle export in this workspace.

Short version:

- The **round-trip process** is the same for both EPUBs: unpack, edit, repack, validate.
- The **file structure** is not the same.
- The **CSS schema** is not the same.
- The **content intent** is often mappable, but the exact class names usually are not.

## Mapping Summary

| Area | Affinity EPUB | Vellum EPUB | Mappable? | Notes |
|---|---|---|---|---|
| Package file | `OEBPS/package.opf` | `OEBPS/content.opf` | Partial | Same purpose, different filename and generated metadata layout. |
| Navigation | `OEBPS/toc.xhtml` | `OEBPS/toc.xhtml` + `OEBPS/toc.ncx` | Partial | Vellum includes both EPUB 3 nav and NCX for Kindle compatibility. |
| Main content | One primary XHTML file (`Story1.xhtml`) | Multiple chapter XHTML files | Partial | Same content can be edited, but Vellum splits the book into smaller files. |
| CSS | `OEBPS/css/styles.css` | `OEBPS/css/style.css` + `OEBPS/css/media.css` | Partial | Same styling role, different organization. |
| Fonts | Embedded Arial fonts | Embedded Cormorant fonts | Yes | Embedded fonts are handled the same way structurally, but the font families differ. |
| Front matter | Usually within one content stream | Separate title page, contents, copyright | Partial | Same concepts, different file breakdown. |
| Images | Inline or linked assets | Separate image assets + SVG badges | Yes | Both are ordinary EPUB assets once unpacked. |
| Metadata | Standard EPUB metadata in OPF | Standard EPUB metadata in OPF plus Vellum extras | Partial | Core metadata maps; Vellum adds accessibility and generator metadata. |

## What Is Directly Mappable

These are conceptually the same in both EPUBs and can usually be moved or recreated without structural surprises:

- Book title
- Author name
- Chapter order
- Paragraph content
- Inline emphasis like italics or bold
- Hyperlinks
- Images and cover assets
- Embedded fonts
- TOC entries
- Basic EPUB metadata such as title, creator, language, and identifier

## What Is Partially Mappable

These concepts map, but not with identical file layouts or CSS selectors:

- **Paragraph styling**: Affinity uses generated style classes like `.Normal_Body_Text`, `.Heading_1`, `.Title`; Vellum uses semantic selectors like `p`, `p.subsq`, `.section-title`, `.page-break`.
- **Headings**: both support chapter headings, but the markup patterns differ.
- **Front matter**: both support title pages and contents pages, but Vellum separates them into dedicated XHTML files more aggressively.
- **TOC structure**: both can produce navigable tables of contents, but Vellum also includes `toc.ncx`.
- **Page breaks and scene breaks**: both can represent them, but the class names and wrappers differ.
- **Font-face declarations**: both use `@font-face`, but the font family names and references are different.
- **Metadata extensions**: both can carry extra EPUB metadata, but the vendor-specific extras do not map one-to-one.

## What Is Not Directly Mappable

These are the main things that do not translate cleanly from one export to the other:

- **Affinity-generated class names** do not map directly to Vellum classes.
- **Vellum-generated wrapper classes** like `element-*`, `heading-*`, `title-page-*`, and `ttext` do not exist in the Affinity export.
- **Vellum’s split stylesheet model** (`style.css` + `media.css`) does not match Affinity’s single stylesheet export.
- **Vellum’s accessibility and generator metadata** are Vellum-specific and should not be expected in Affinity output.
- **Vellum’s per-chapter file split** is not the same as Affinity’s single-story XHTML layout.
- **Vellum’s Kindle-targeted packaging details** such as `toc.ncx` are not a direct Affinity equivalent.

## Selector-Level Mapping

This is the practical CSS mapping view.

| Affinity selector pattern | Vellum equivalent | Status | Notes |
|---|---|---|---|
| `.Heading_1`, `.Heading_2` | `.section-title`, heading elements inside chapter/title-page wrappers | Partial | Same semantic role, different generated class system. |
| `.Title` | `.title-page-title`, `.element-title`, `.title-page-contributor` | Partial | Vellum splits title-page semantics across several classes. |
| `.Normal_Body_Text` | `p` and `p.subsq` | Partial | Affinity emits a style class per paragraph role; Vellum often relies on element + semantic class. |
| `.Bullet_List`, `.Bullet_2nd_Level` | `ul`, `ol`, `li`, `li.over-indented` | Partial | List semantics map, but the exact class structure differs. |
| `.Hyperlink` | `a`, `a.link-contains-image` | Partial | Link styling is present in both, but Vellum keeps it more semantic. |
| `.Tips_and_Tricks_Special_Italics` | `blockquote`, `p.blockquote-content`, `span.smallcaps` or custom semantic blocks | Partial | You can map the intent, not the exact generated class. |
| `.Inline_Italics` | `span` with inline emphasis | Yes | This is a straightforward semantic match. |
| `.Green_Text` | custom inline span classes such as `span.smallcaps` or a new semantic span | Partial | Color-specific styling is portable, but the class name is not. |
| page-break spans like `role="doc-pagebreak"` | `.page-break`, `.scene-break`, `epub:type="pagebreak"` | Partial | Both can express breaks, but Vellum uses a richer structural model. |

## Structure-Level Mapping

| Structure | Affinity | Vellum | Mappable? | Notes |
|---|---|---|---|---|
| Single story XHTML | Yes | No | Partial | Vellum splits the book into chapter files. |
| Multi-file chapter structure | No | Yes | Partial | You can convert Affinity content into this format, but not by direct rename. |
| Single CSS file | Yes | No | Partial | Vellum separates screen/media behavior. |
| Print-friendly `media.css` layer | No | Yes | Partial | Vellum uses a second stylesheet for alternate presentation. |
| EPUB 3 navigation document | Yes | Yes | Yes | Both support modern EPUB navigation. |
| NCX navigation file | No | Yes | Partial | Kindle-targeted Vellum output includes it. |

## Practical Rule Set

If your goal is to move from Affinity to a Vellum-like EPUB structure, treat the mapping this way:

1. Map **content meaning** first, not class names.
2. Rebuild **chapter boundaries** into separate XHTML files if you want Vellum parity.
3. Recreate **typographic intent** in Vellum CSS, instead of copying Affinity selectors verbatim.
4. Preserve **metadata and asset references** where they make sense.
5. Re-test the EPUB after every structural change.

## Bottom Line

The answer to “what is mappable?” is:

- **Mappable:** content, reading order, basic metadata, TOC intent, images, fonts, and broad styling intent.
- **Partially mappable:** headings, body text styles, lists, breaks, front matter, and stylesheet behavior.
- **Not directly mappable:** exact generated class names, file layout, and vendor-specific EPUB packaging details.

If you want, the next useful artifact would be a **selector crosswalk** that lists Affinity class names on one side and the closest Vellum semantic equivalent on the other.