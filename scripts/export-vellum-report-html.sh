#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

source_markdown="${1:-$VELLUM_COMPARE_REPORT}"
output_html="${2:-$VELLUM_COMPARE_HTML_REPORT}"

mkdir -p "$(dirname "$output_html")"

python3 - "$source_markdown" "$output_html" <<'PY'
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

source_markdown = Path(sys.argv[1])
output_html = Path(sys.argv[2])

text = source_markdown.read_text(encoding="utf-8").splitlines()


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def strip_markdown_prefix(line: str, prefix: str) -> str:
    return line[len(prefix):].strip()


def is_kv_line(line: str) -> bool:
    return bool(re.match(r"^[A-Za-z][A-Za-z0-9 ]*:\s+.+$", line))


def render_inline(value: str) -> str:
    rendered = esc(value)
    rendered = re.sub(r"`([^`]+)`", r"<code>\1</code>", rendered)
    rendered = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', rendered)
    return rendered


def parse_sections(lines: list[str]) -> dict[str, object]:
    title = ""
    intro: list[str] = []
    sections: list[dict[str, object]] = []
    current: dict[str, object] | None = None

    for raw in lines:
        line = raw.rstrip()
        if not line:
            if current is None:
                if intro and intro[-1] != "":
                    intro.append("")
            else:
                body = current.setdefault("body", [])
                if body and body[-1] != "":
                    body.append("")
            continue

        if line.startswith("# ") and not title:
            title = strip_markdown_prefix(line, "# ")
            continue

        if line.startswith("## "):
            current = {"title": strip_markdown_prefix(line, "## "), "body": []}
            sections.append(current)
            continue

        if current is None:
            intro.append(line)
        else:
            current.setdefault("body", []).append(line)

    return {"title": title, "intro": intro, "sections": sections}


def render_bullets(lines: list[str]) -> str:
    items = []
    for line in lines:
        if line.startswith("- "):
            items.append(f"<li>{render_inline(line[2:].strip())}</li>")
    return "<ul>" + "".join(items) + "</ul>"


def render_definition_list(lines: list[str]) -> str:
    rows = []
    for line in lines:
        if is_kv_line(line):
            key, value = line.split(":", 1)
            rows.append(f"<div class=\"kv-row\"><span>{render_inline(key.strip())}</span><strong>{render_inline(value.strip())}</strong></div>")
    return '<div class="kv-grid">' + "".join(rows) + '</div>'


def render_body(lines: list[str]) -> str:
    parts: list[str] = []
    current_bullets: list[str] = []
    current_paragraph: list[str] = []

    def flush_paragraph() -> None:
        if current_paragraph:
            paragraph = " ".join(part for part in current_paragraph if part).strip()
            if paragraph:
                parts.append(f"<p>{render_inline(paragraph)}</p>")
            current_paragraph.clear()

    def flush_bullets() -> None:
        if current_bullets:
            parts.append(render_bullets(current_bullets))
            current_bullets.clear()

    for line in lines:
        if not line:
            flush_paragraph()
            flush_bullets()
            continue

        if line.startswith("### "):
            flush_paragraph()
            flush_bullets()
            parts.append(f"<h3>{render_inline(strip_markdown_prefix(line, '### '))}</h3>")
            continue

        if line.startswith("#### "):
            flush_paragraph()
            flush_bullets()
            parts.append(f"<h4>{render_inline(strip_markdown_prefix(line, '#### '))}</h4>")
            continue

        if line.startswith("- "):
            flush_paragraph()
            current_bullets.append(line)
            continue

        if is_kv_line(line):
            flush_paragraph()
            flush_bullets()
            parts.append(render_definition_list([line]))
            continue

        flush_bullets()
        current_paragraph.append(line)

    flush_paragraph()
    flush_bullets()
    return "".join(parts)


parsed = parse_sections(text)
title = parsed["title"] or "Vellum Package Comparison Report"
intro = parsed["intro"]
sections = parsed["sections"]

left_source = ""
right_source = ""
counts = {}

for section in sections:
    section_title = section["title"]
    body = section.get("body", [])
    if section_title == "Counts":
        for line in body:
            if is_kv_line(line):
                key, value = line.split(":", 1)
                counts[key.strip()] = value.strip()

for line in intro:
    if line.startswith("Left:"):
        left_source = line.split(":", 1)[1].strip()
    elif line.startswith("Right:"):
        right_source = line.split(":", 1)[1].strip()

summary_count = counts.get("Changed", counts.get("Images", "0"))
status = "Match" if summary_count == "0" else "Differences"

metric_rows = [
    ("Left source", left_source or "(unknown)"),
    ("Right source", right_source or "(unknown)"),
    ("Changed files", summary_count),
    ("Status", status),
]

section_html = []
for idx, section in enumerate(sections, start=1):
    section_title = section["title"]
    body = section.get("body", [])
    body_clean = [line.strip() for line in body if line.strip()]

    if section_title == "Counts":
        content_html = '<table class="table" role="presentation"><tr><th>Metric</th><th>Value</th></tr>'
        for key in ["Common files", "Left only", "Right only", "Plist", "Content", "Images", "Other"]:
            content_html += f"<tr><td>{esc(key)}</td><td>{esc(counts.get(key, '0'))}</td></tr>"
        content_html += "</table>"
        display_summary = "Summary metrics"
    else:
        if not body_clean or body_clean == ["(none)"]:
            content_html = '<div class="empty">No differences detected in this section.</div>'
            display_summary = "(none)"
        else:
            content_html = render_body(body)
            if not content_html:
                content_html = '<div class="empty">No differences detected in this section.</div>'
                display_summary = "(none)"
            else:
                display_summary = "See details"

    section_html.append(
        f"""
        <details class=\"section\" {'open' if idx == 1 else ''}>
          <summary><span class=\"label-strong\"><span class=\"badge\">{idx}</span>{esc(section_title)}</span><span>{esc(display_summary)}</span></summary>
          <div class=\"body\">{content_html}</div>
        </details>
        """
    )

html_output = f"""<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>{esc(title)}</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #0b1020;
      --bg-soft: rgba(255, 255, 255, 0.05);
      --panel: rgba(18, 24, 45, 0.82);
      --panel-strong: rgba(25, 33, 60, 0.94);
      --line: rgba(255, 255, 255, 0.10);
      --line-strong: rgba(255, 255, 255, 0.16);
      --text: #eaf0ff;
      --muted: #a8b3d1;
      --accent: #86c5ff;
      --accent-strong: #4fb4ff;
      --good: #8ef0b5;
      --warn: #ffd08a;
      --shadow: 0 24px 80px rgba(0, 0, 0, 0.42);
      --radius: 20px;
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; min-height: 100vh; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: radial-gradient(circle at top left, rgba(79, 180, 255, 0.22), transparent 28%), radial-gradient(circle at top right, rgba(142, 240, 181, 0.14), transparent 24%), linear-gradient(180deg, #090d1a 0%, #0b1020 46%, #090d17 100%); color: var(--text); }}
    .shell {{ width: min(1180px, calc(100% - 32px)); margin: 0 auto; padding: 28px 0 48px; }}
    .hero {{ position: relative; overflow: hidden; background: linear-gradient(135deg, rgba(22, 30, 56, 0.96), rgba(12, 18, 34, 0.96)); border: 1px solid var(--line); border-radius: 28px; box-shadow: var(--shadow); padding: 30px 28px 26px; }}
    .hero::before, .hero::after {{ content: ""; position: absolute; inset: auto; border-radius: 999px; pointer-events: none; filter: blur(2px); }}
    .hero::before {{ width: 420px; height: 420px; background: radial-gradient(circle, rgba(79, 180, 255, 0.18), transparent 70%); right: -180px; top: -180px; }}
    .hero::after {{ width: 260px; height: 260px; background: radial-gradient(circle, rgba(142, 240, 181, 0.12), transparent 70%); left: -100px; bottom: -100px; }}
    .eyebrow {{ display: inline-flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 999px; background: rgba(255, 255, 255, 0.05); border: 1px solid var(--line); color: var(--muted); letter-spacing: 0.08em; text-transform: uppercase; font-size: 0.74rem; font-weight: 700; position: relative; z-index: 1; }}
    h1 {{ margin: 16px 0 10px; font-size: clamp(2rem, 5vw, 3.8rem); line-height: 0.98; letter-spacing: -0.04em; max-width: 11ch; position: relative; z-index: 1; }}
    .subhead {{ margin: 0; max-width: 66ch; font-size: 1.02rem; line-height: 1.7; color: var(--muted); position: relative; z-index: 1; }}
    .meta-grid {{ display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; margin-top: 22px; position: relative; z-index: 1; }}
    .metric {{ background: rgba(255, 255, 255, 0.04); border: 1px solid var(--line); border-radius: 18px; padding: 14px 16px; backdrop-filter: blur(14px); }}
    .metric .label {{ display: block; color: var(--muted); font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 8px; }}
    .metric .value {{ font-size: 1.18rem; font-weight: 700; letter-spacing: -0.02em; }}
    .grid {{ display: grid; grid-template-columns: 1.1fr 0.9fr; gap: 18px; margin-top: 18px; }}
    .panel {{ background: linear-gradient(180deg, var(--panel), rgba(13, 18, 34, 0.82)); border: 1px solid var(--line); border-radius: var(--radius); box-shadow: var(--shadow); padding: 22px; }}
    .panel h2 {{ margin: 0 0 14px; font-size: 1.05rem; letter-spacing: -0.02em; }}
    .chips {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 16px; }}
    .chip {{ display: inline-flex; align-items: center; gap: 8px; padding: 9px 12px; border-radius: 999px; background: rgba(255, 255, 255, 0.05); border: 1px solid var(--line); color: var(--text); font-size: 0.88rem; }}
    .chip strong {{ color: var(--accent); font-weight: 700; }}
    .section {{ margin-top: 18px; border: 1px solid var(--line); border-radius: 18px; overflow: hidden; background: rgba(255, 255, 255, 0.03); }}
    .section summary {{ list-style: none; cursor: pointer; padding: 16px 18px; display: flex; align-items: center; justify-content: space-between; gap: 14px; font-weight: 700; border-bottom: 1px solid transparent; }}
    .section[open] summary {{ border-bottom-color: var(--line); background: rgba(255, 255, 255, 0.03); }}
    .section summary::-webkit-details-marker {{ display: none; }}
    .section .body {{ padding: 16px 18px 18px; color: var(--muted); line-height: 1.65; }}
    .empty {{ padding: 16px 18px; border-radius: 16px; border: 1px dashed var(--line-strong); background: rgba(255, 255, 255, 0.03); color: var(--muted); }}
    .empty strong, .callout strong {{ color: var(--text); }}
    .callout {{ margin-top: 16px; padding: 16px 18px; border-radius: 16px; background: linear-gradient(135deg, rgba(79, 180, 255, 0.12), rgba(142, 240, 181, 0.08)); border: 1px solid rgba(134, 197, 255, 0.18); color: var(--muted); }}
    .table {{ width: 100%; border-collapse: collapse; overflow: hidden; border-radius: 16px; border: 1px solid var(--line); }}
    .table th, .table td {{ padding: 12px 14px; text-align: left; vertical-align: top; border-bottom: 1px solid var(--line); font-size: 0.95rem; }}
    .table th {{ color: var(--muted); font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.08em; background: rgba(255, 255, 255, 0.04); }}
    .table tr:last-child td {{ border-bottom: 0; }}
    .footer {{ margin-top: 20px; color: var(--muted); font-size: 0.88rem; text-align: center; }}
    .label-strong {{ display: inline-flex; align-items: center; gap: 8px; color: var(--text); }}
    .badge {{ display: inline-flex; align-items: center; justify-content: center; min-width: 22px; height: 22px; padding: 0 8px; border-radius: 999px; background: rgba(134, 197, 255, 0.14); border: 1px solid rgba(134, 197, 255, 0.28); color: var(--accent); font-size: 0.78rem; font-weight: 700; }}
    .kv-grid {{ display: grid; gap: 10px; }}
    .kv-row {{ display: flex; justify-content: space-between; gap: 16px; padding: 12px 14px; border-radius: 14px; background: rgba(255, 255, 255, 0.04); border: 1px solid var(--line); }}
    .kv-row span {{ color: var(--muted); }}
    .kv-row strong {{ color: var(--text); font-weight: 700; text-align: right; }}
    ul {{ margin: 0; padding-left: 22px; }}
    li + li {{ margin-top: 8px; }}
    h3, h4 {{ margin: 18px 0 10px; color: var(--text); }}
    code {{ padding: 0.1em 0.35em; border-radius: 8px; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.08); }}
    @media (max-width: 960px) {{ .meta-grid, .grid {{ grid-template-columns: 1fr; }} h1 {{ max-width: none; }} }}
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <div class="eyebrow">Vellum package report</div>
      <h1>{esc(title)}</h1>
      <p class="subhead">A polished HTML export of the markdown comparison report, built to be easier to scan than a plain preview while keeping the underlying report structure intact.</p>
      <div class="meta-grid" aria-label="Report summary metrics">
        {''.join(f'<div class="metric"><span class="label">{esc(label)}</span><span class="value">{esc(value)}</span></div>' for label, value in metric_rows)}
      </div>
    </section>

    <div class="grid">
      <section class="panel">
        <h2>Report Sections</h2>
        {''.join(section_html)}
      </section>

      <aside class="panel">
        <h2>Snapshot Details</h2>
        <table class="table" role="presentation">
          <tr><th>Metric</th><th>Value</th></tr>
          <tr><td>Common files</td><td>{esc(counts.get('Common files', '0'))}</td></tr>
          <tr><td>Left only</td><td>{esc(counts.get('Left only', '0'))}</td></tr>
          <tr><td>Right only</td><td>{esc(counts.get('Right only', '0'))}</td></tr>
          <tr><td>Plist</td><td>{esc(counts.get('Plist', '0'))}</td></tr>
          <tr><td>Content</td><td>{esc(counts.get('Content', '0'))}</td></tr>
          <tr><td>Images</td><td>{esc(counts.get('Images', '0'))}</td></tr>
          <tr><td>Other</td><td>{esc(counts.get('Other', '0'))}</td></tr>
        </table>

        <div class="chips" aria-label="Report tags">
                    <span class="chip"><strong>Source</strong> {esc(left_source or 'tests/fixtures/vellum')}</span>
          <span class="chip"><strong>Target</strong> {esc(right_source or 'vellum export')}</span>
          <span class="chip"><strong>Output</strong> HTML scaffold</span>
          <span class="chip"><strong>Style</strong> Editorial dark UI</span>
        </div>

        <div class="callout">
          <strong>Output path:</strong> {esc(output_html.as_posix())}<br />
          The exporter reads the markdown report and writes a matching HTML version into <code>reports/html-versions</code>.
        </div>
      </aside>
    </div>

    <div class="footer">
      Generated from {esc(source_markdown.as_posix())}.
    </div>
  </main>
</body>
</html>
"""

output_html.write_text(html_output, encoding="utf-8")
print(output_html)
PY
