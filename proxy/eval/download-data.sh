#!/usr/bin/env bash
# Download a small Nutrition5k eval subset (metadata + N overhead photos) over plain HTTPS.
# Data: https://github.com/google-research-datasets/Nutrition5k (CC BY 4.0)
# Usage: ./download-data.sh [N]   (default 50 dishes; re-run safe, skips existing files)
set -euo pipefail

N="${1:-50}"
BASE="https://storage.googleapis.com/nutrition5k_dataset/nutrition5k_dataset"
DIR="$(cd "$(dirname "$0")" && pwd)/data"
mkdir -p "$DIR/images"

echo "→ metadata + depth-test split (dishes guaranteed to have overhead photos)"
for f in metadata/dish_metadata_cafe1.csv metadata/dish_metadata_cafe2.csv dish_ids/splits/depth_test_ids.txt; do
  out="$DIR/$(basename "$f")"
  [ -s "$out" ] || curl -sf "$BASE/$f" -o "$out"
done

echo "→ selecting first $N test dishes present in metadata"
cut -d, -f1 "$DIR"/dish_metadata_cafe*.csv | sort > "$DIR/.meta_ids"
grep -Fxf "$DIR/.meta_ids" "$DIR/depth_test_ids.txt" | head -n "$N" > "$DIR/eval_ids.txt"
COUNT=$(wc -l < "$DIR/eval_ids.txt" | tr -d ' ')
echo "   $COUNT dishes selected → data/eval_ids.txt"

echo "→ downloading overhead photos (skipping any already present)"
i=0
while read -r id; do
  out="$DIR/images/$id.png"
  if [ ! -s "$out" ]; then
    curl -sf "$BASE/imagery/realsense_overhead/$id/rgb.png" -o "$out" \
      || { echo "   ✗ $id (no overhead image, removing from eval set)"; rm -f "$out"; continue; }
  fi
  i=$((i+1)); printf "   %d/%s %s\r" "$i" "$COUNT" "$id"
done < "$DIR/eval_ids.txt"
# keep eval_ids.txt in sync with what actually downloaded
ls "$DIR/images" | sed 's/\.png$//' | grep -Fxf - "$DIR/eval_ids.txt" > "$DIR/.ok" && mv "$DIR/.ok" "$DIR/eval_ids.txt"

echo ""
echo "✓ done: $(ls "$DIR/images" | wc -l | tr -d ' ') photos in data/images/, ground truth in data/dish_metadata_cafe*.csv"
