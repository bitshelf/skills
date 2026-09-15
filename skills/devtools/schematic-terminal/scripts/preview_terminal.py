#!/usr/bin/env python3
"""Create a dependency-free HTML preview for a terminal schematic."""
from __future__ import annotations

import argparse
import html
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("diagram", type=Path)
    ap.add_argument("output", type=Path, nargs="?", default=Path("/tmp/schematic-terminal-preview.html"))
    args = ap.parse_args()

    text = args.diagram.read_text(encoding="utf-8")
    body = html.escape(text)
    doc = f"""<!doctype html>
<meta charset=\"utf-8\">
<title>Schematic terminal preview</title>
<style>
  body {{ margin: 24px; background: #fff; color: #111; }}
  pre {{ font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, \"Liberation Mono\", monospace;
         font-size: 15px; line-height: 1.35; white-space: pre; }}
</style>
<pre>{body}</pre>
"""
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(doc, encoding="utf-8")
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
