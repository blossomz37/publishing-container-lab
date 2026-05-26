#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/config.sh"

source_markdown="${1:-$COMPARE_REPORT}"
output_html="${2:-$EPUB_COMPARE_HTML_REPORT}"

mkdir -p "$(dirname "$output_html")"

python3 - "$source_markdown" "$output_html" <<'PY'
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

source_markdown = Path(sys.argv[1])
output_html = Path(sys.argv[2])

lines = source_markdown.read_text(encoding="utf-8").splitlines()


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def render_inline(value: str) -> str:
    rendered = esc(value)
    rendered = re.sub(r"`([^`]+)`", r"<code>\1</code>", rendered)
    rendered = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', rendered)
    return rendered


def parse_sections(text_lines: list[str]) -> tuple[str, list[str], list[dict[str, list[str] | str]]]:
    title = ""
    intro: list[str] = []
    sections: list[dict[str, list[str] | str]] = []
    current: dict[str, list[str] | str] | None = None

    for raw in text_lines:
        line = raw.rstrip("\n")

        if line.startswith("# ") and not title:
            title = line[2:].strip()
            continue

        if line.startswith("## "):
            current = {"title": line[3:].strip(), "body": []}
            sections.append(current)
            continue

        if current is None:
            intro.append(line)
        else:
            body = current["body"]
            assert isinstance(body, list)
            body.append(line)

    return title, intro, sections


def extract_left_right(intro: list[str]) -> tuple[str, str]:
    left = ""
    right = ""
    for line in intro:
        if line.startswith("Left:"):
            left = line.split(":", 1)[1].strip()
        elif line.startswith("Right:"):
            right = line.split(":", 1)[1].strip()
    return left, right


def section_by_title(sections: list[dict[str, list[str] | str]], name: str) -> list[str]:
    for section in sections:
        if section.get("title") == name:
            body = section.get("body", [])
            assert isinstance(body, list)
            return body
    return []


def has_no_differences(section_body: list[str]) -> bool:
    body_text = "\n".join(section_body).lower()
    return "(no normalized" in body_text and "differences)" in body_text


def render_body(section_body: list[str]) -> str:
    has_bullets = any(line.strip().startswith("- ") for line in section_body)
    has_diff = any(line.startswith("--- ") or line.startswith("+++ ") or line.startswith("@@ ") for line in section_body)

    if has_bullets and not has_diff:
        items = []
        for line in section_body:
            stripped = line.strip()
            if stripped.startswith("- "):
                items.append(f"<li>{render_inline(stripped[2:])}</li>")
        return "<ul>" + "".join(items) + "</ul>" if items else ""

    # Keep diff blocks readable and monospaced.
    text = "\n".join(section_body).strip()
    if not text:
        return ""
    return f"<pre>{esc(text)}</pre>"


title, intro, sections = parse_sections(lines)
if not title:
    title = "EPUB Comparison Report"

left_source, right_source = extract_left_right(intro)
content_body = section_by_title(sections, "Content Comparison")
css_body = section_by_title(sections, "Stylesheet Comparison")
summary_body = section_by_title(sections, "Input Summary")

content_status = "Match" if has_no_differences(content_body) else "Differences"
css_status = "Match" if has_no_differences(css_body) else "Differences"
overall_status = "Match" if content_status == "Match" and css_status == "Match" else "Differences"

summary_rows: list[tuple[str, str]] = []
for line in summary_body:
    if ":" in line:
        key, value = line.split(":", 1)
        summary_rows.append((key.strip(), value.strip()))

section_html = []
for idx, section in enumerate(sections, start=1):
    section_title = str(section.get("title", "Section"))
    section_body = section.get("body", [])
    assert isinstance(section_body, list)

    if has_no_differences(section_body):
        body_html = '<div class="empty">No differences detected in this section.</div>'
        summary = "(none)"
    else:
        body_html = render_body(section_body)
        if not body_html:
            body_html = '<div class="empty">No content in this section.</div>'
            summary = "(empty)"
        else:
            summary = "See details"

    section_html.append(
        f"""
        <details class=\"section\" {'open' if idx == 1 else ''}>
          <summary><span class=\"label-strong\"><span class=\"badge\">{idx}</span>{esc(section_title)}</span><span>{esc(summary)}</span></summary>
          <div class=\"body\">{body_html}</div>
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
      --panel: rgba(18, 24, 45, 0.82);
      --line: rgba(255, 255, 255, 0.10);
      --line-strong: rgba(255, 255, 255, 0.16);
      --text: #eaf0ff;
      --muted: #a8b3d1;
      --accent: #86c5ff;
      --shadow: 0 24px 80px rgba(0, 0, 0, 0.42);
      --radius: 20px;
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; min-height: 100vh; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: radial-gradient(circle at top left, rgba(79, 180, 255, 0.22), transparent 28%), linear-gradient(180deg, #090d1a 0%, #0b1020 46%, #090d17 100%); color: var(--text); }}
    .shell {{ width: min(1180px, calc(100% - 32px)); margin: 0 auto; padding: 28px 0 48px; }}
    .hero {{ background: linear-gradient(135deg, rgba(22, 30, 56, 0.96), rgba(12, 18, 34, 0.96)); border: 1px solid var(--line); border-radius: 28px; box-shadow: var(--shadow); padding: 30px 28px 26px; }}
    .eyebrow {{ display: inline-flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 999px; background: rgba(255, 255, 255, 0.05); border: 1px solid var(--line); color: var(--muted); letter-spacing: 0.08em; text-transform: uppercase; font-size: 0.74rem; font-weight: 700; }}
    h1 {{ margin: 16px 0 10px; font-size: clamp(2rem, 5vw, 3.4rem); line-height: 1.0; letter-spacing: -0.03em; }}
    .subhead {{ margin: 0; max-width: 66ch; font-size: 1.02rem; line-height: 1.7; color: var(--muted); }}
    .meta-grid {{ display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 14px; margin-top: 22px; }}
    .metric {{ background: rgba(255, 255, 255, 0.04); border: 1px solid var(--line); border-radius: 18px; padding: 14px 16px; }}
    .metric .label {{ display: block; color: var(--muted); font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 8px; }}
    .metric .value {{ font-size: 1.05rem; font-weight: 700; letter-spacing: -0.02em; }}
    .grid {{ display: grid; grid-template-columns: 1.2fr 0.8fr; gap: 18px; margin-top: 18px; }}
    .panel {{ background: linear-gradient(180deg, var(--panel), rgba(13, 18, 34, 0.82)); border: 1px solid var(--line); border-radius: var(--radius); box-shadow: var(--shadow); padding: 22px; }}
    .panel h2 {{ margin: 0 0 14px; font-size: 1.05rem; letter-spacing: -0.02em; }}
    .section {{ margin-top: 18px; border: 1px solid var(--line); border-radius: 18px; overflow: hidden; background: rgba(255, 255, 255, 0.03); }}
    .section summary {{ list-style: none; cursor: pointer; padding: 16px 18px; display: flex; align-items: center; justify-content: space-between; gap: 14px; font-weight: 700; border-bottom: 1px solid transparent; }}
    .section[open] summary {{ border-bottom-color: var(--line); background: rgba(255, 255, 255, 0.03); }}
    .section summary::-webkit-details-marker {{ display: none; }}
    .section .body {{ padding: 16px 18px 18px; color: var(--muted); line-height: 1.65; }}
    .empty {{ padding: 16px 18px; border-radius: 16px; border: 1px dashed var(--line-strong); background: rgba(255, 255, 255, 0.03); color: var(--muted); }}
    .table {{ width: 100%; border-collapse: collapse; overflow: hidden; border-radius: 16px; border: 1px solid var(--line); }}
    .table th, .table td {{ padding: 12px 14px; text-align: left; vertical-align: top; border-bottom: 1px solid var(--line); font-size: 0.95rem; }}
    .table th {{ color: var(--muted); font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.08em; background: rgba(255, 255, 255, 0.04); }}
    .table tr:last-child td {{ border-bottom: 0; }}
    .label-strong {{ display: inline-flex; align-items: center; gap: 8px; color: var(--text); }}
    .badge {{ display: inline-flex; align-items: center; justify-content: center; min-width: 22px; height: 22px; padding: 0 8px; border-radius: 999px; background: rgba(134, 197, 255, 0.14); border: 1px solid rgba(134, 197, 255, 0.28); color: var(--accent); font-size: 0.78rem; font-weight: 700; }}
    pre {{ margin: 0; padding: 14px; border-radius: 12px; overflow: auto; background: rgba(0, 0, 0, 0.28); border: 1px solid var(--line); color: #d5def8; font: 0.88rem/1.45 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace; }}
    ul {{ margin: 0; padding-left: 22px; }}
    li + li {{ margin-top: 8px; }}
    .footer {{ margin-top: 20px; color: var(--muted); font-size: 0.88rem; text-align: center; }}
    @media (max-width: 960px) {{ .meta-grid, .grid {{ grid-template-columns: 1fr; }} }}
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <div class="eyebrow">EPUB content/style report</div>
      <h1>{esc(title)}</h1>
      <p class="subhead">A styled HTML export of the EPUB markdown comparison report, focused on normalized content and stylesheet differences.</p>
      <div class="meta-grid" aria-label="Report summary metrics">
        <div class="metric"><span class="label">Left source</span><span class="value">{esc(left_source or '(unknown)')}</span></div>
        <div class="metric"><span class="label">Right source</span><span class="value">{esc(right_source or '(unknown)')}</span></div>
        <div class="metric"><span class="label">Content</span><span class="value">{esc(content_status)}</span></div>
        <div class="metric"><span class="label">Stylesheet</span><span class="value">{esc(css_status)}</span></div>
        <div class="metric"><span class="label">Overall</span><span class="value">{esc(overall_status)}</span></div>
      </div>
    </section>

    <div class="grid">
      <section class="panel">
        <h2>Report Sections</h2>
        {''.join(section_html)}
      </section>

      <aside class="panel">
        <h2>Input Summary</h2>
        <table class="table" role="presentation">
          <tr><th>Metric</th><th>Value</th></tr>
          {''.join(f'<tr><td>{esc(k)}</td><td>{esc(v)}</td></tr>' for k, v in summary_rows) if summary_rows else '<tr><td colspan="2">No summary values found.</td></tr>'}
        </table>
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
