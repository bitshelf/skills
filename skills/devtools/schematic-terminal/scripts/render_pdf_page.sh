#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "Usage: $0 <file.pdf> <page-number> [output.png] [dpi]" >&2
  exit 2
fi

pdf=$1
page=$2
out=${3:-"/tmp/schematic-page-${page}.png"}
dpi=${4:-280}

[[ -f "$pdf" ]] || { echo "error: file not found: $pdf" >&2; exit 1; }
[[ "$page" =~ ^[1-9][0-9]*$ ]] || { echo "error: page must be >= 1" >&2; exit 1; }
[[ "$dpi" =~ ^[1-9][0-9]*$ ]] || { echo "error: dpi must be a positive integer" >&2; exit 1; }

mkdir -p "$(dirname "$out")"

tmp_base="${out%.png}"

if command -v pdftoppm >/dev/null 2>&1; then
  pdftoppm -f "$page" -singlefile -r "$dpi" -png "$pdf" "$tmp_base"
  # pdftoppm adds .png; if output already ended in .png, tmp_base keeps naming stable.
  generated="${tmp_base}.png"
  if [[ "$generated" != "$out" ]]; then mv -f "$generated" "$out"; fi
elif command -v mutool >/dev/null 2>&1; then
  mutool draw -q -r "$dpi" -F png -o "$out" "$pdf" "$page"
else
  echo "error: need pdftoppm (poppler-utils) or mutool" >&2
  exit 1
fi

printf '%s\n' "$out"
