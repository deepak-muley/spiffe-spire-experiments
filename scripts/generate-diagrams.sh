#!/bin/bash
# Generate SVG images from Mermaid diagram source files
# Requires: npm/npx (mermaid-cli will be fetched via npx)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIAGRAMS_DIR="$(dirname "$SCRIPT_DIR")/docs/diagrams"
cd "$DIAGRAMS_DIR"

echo ">>> Generating diagrams in $DIAGRAMS_DIR"

for mmd in *.mmd; do
  base="${mmd%.mmd}"
  echo "  - $mmd -> $base.svg"
  npx -p @mermaid-js/mermaid-cli mmdc -i "$mmd" -o "${base}.svg" -b transparent 2>/dev/null || {
    echo "  ERROR: Failed to generate $base.svg. Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 1
  }
done

echo ">>> Done. Generated SVG files:"
ls -la *.svg 2>/dev/null || true
