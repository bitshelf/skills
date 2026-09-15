#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <file.pdf> <grep-extended-regex>" >&2
  exit 2
fi

pdf=$1
pattern=$2
[[ -f "$pdf" ]] || { echo "error: file not found: $pdf" >&2; exit 1; }
command -v pdftotext >/dev/null 2>&1 || { echo "error: pdftotext not found (install poppler-utils)" >&2; exit 1; }

if command -v pdfinfo >/dev/null 2>&1; then
  pages=$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2; exit}')
else
  # Fallback: form-feed count from pdftotext. Good enough for page-location assistance.
  pages=$(pdftotext -layout "$pdf" - | awk 'BEGIN{RS="\f"} END{print NR}')
fi

found=0
for ((p=1; p<=pages; p++)); do
  text=$(pdftotext -f "$p" -l "$p" -layout "$pdf" - 2>/dev/null || true)
  if grep -Eiq -- "$pattern" <<<"$text"; then
    found=1
    echo "page $p"
    grep -Ein -- "$pattern" <<<"$text" | head -n 8 | sed 's/^/  /'
  fi
done

if [[ $found -eq 0 ]]; then
  echo "no text match; PDF may be scanned or the label may be encoded poorly" >&2
  exit 1
fi
