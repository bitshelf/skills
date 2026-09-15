#!/usr/bin/env python3
"""Lightweight presentation lint for terminal schematic diagrams.

This script intentionally does NOT prove electrical correctness.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

BOX = set("┌┐└┘├┤┬┴┼─│")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("diagram", type=Path)
    ap.add_argument("--max-width", type=int, default=140)
    args = ap.parse_args()

    text = args.diagram.read_text(encoding="utf-8")
    lines = text.splitlines()
    warnings: list[str] = []

    if "\t" in text:
        warnings.append("tabs found: tabs make terminal alignment renderer-dependent")
    if "+" in text:
        warnings.append("'+' found: avoid '+' as an electrical junction; use Unicode box-drawing characters")
    if "┼" in text:
        warnings.append("'┼' found: four-way crossings are usually ambiguous; verify this is a real junction")

    for idx, line in enumerate(lines, 1):
        width = len(line.expandtabs(8))
        if width > args.max_width:
            warnings.append(f"line {idx}: width {width} exceeds --max-width {args.max_width}")
        if line.rstrip() != line:
            warnings.append(f"line {idx}: trailing whitespace")
        if re.search(r"[|]-|-[|]", line):
            warnings.append(f"line {idx}: mixed ASCII wire characters ('|'/'-'); prefer Unicode box drawing")

    if not any(ch in BOX for ch in text):
        warnings.append("no Unicode box-drawing characters found; confirm the diagram is intentionally minimal")

    print(f"lines={len(lines)} max_width={max((len(x) for x in lines), default=0)}")
    if warnings:
        print("WARNINGS:")
        for w in warnings:
            print(f"- {w}")
        print("Reminder: this is presentation lint only; re-trace against the connection ledger.")
        return 1

    print("OK: no presentation lint warnings.")
    print("Reminder: electrical correctness still requires re-tracing against the connection ledger.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
