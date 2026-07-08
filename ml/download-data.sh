#!/usr/bin/env bash
# Download the full Nutrition5k overhead-RGB training subset over plain HTTPS.
# Data: https://github.com/google-research-datasets/Nutrition5k (CC BY 4.0)
# ~3.5k dishes ≈ 2 GB. Resumable: re-running skips files already present.
set -euo pipefail

export BASE="https://storage.googleapis.com/nutrition5k_dataset/nutrition5k_dataset"
export DIR="$(cd "$(dirname "$0")" && pwd)/data"
mkdir -p "$DIR/images"

echo "→ metadata + official depth splits"
for f in metadata/dish_metadata_cafe1.csv metadata/dish_metadata_cafe2.csv \
         dish_ids/splits/depth_train_ids.txt dish_ids/splits/depth_test_ids.txt; do
  out="$DIR/$(basename "$f")"
  [ -s "$out" ] || curl -sf "$BASE/$f" -o "$out"
done

echo "→ building wanted-ID list (in a depth split AND has metadata)"
cat "$DIR/depth_train_ids.txt" "$DIR/depth_test_ids.txt" | sort -u > "$DIR/.split_ids"
cut -d, -f1 "$DIR"/dish_metadata_cafe*.csv | sort -u > "$DIR/.meta_ids"
comm -12 "$DIR/.split_ids" "$DIR/.meta_ids" > "$DIR/wanted_ids.txt"
TOTAL=$(wc -l < "$DIR/wanted_ids.txt" | tr -d ' ')
HAVE=$(ls "$DIR/images" 2>/dev/null | wc -l | tr -d ' ')
echo "   $TOTAL dishes wanted, $HAVE already downloaded"

echo "→ downloading overhead photos (8 parallel, skip existing)"
xargs -P 8 -I ID bash -c '
  out="$DIR/images/ID.png"
  [ -s "$out" ] && exit 0
  curl -sf --retry 3 "$BASE/imagery/realsense_overhead/ID/rgb.png" -o "$out" || rm -f "$out"
' < "$DIR/wanted_ids.txt"

GOT=$(ls "$DIR/images" | wc -l | tr -d ' ')
MISSING=$((TOTAL - GOT))
echo "✓ done: $GOT/$TOTAL photos in data/images/ ($MISSING had no overhead image or failed)"
echo "  disk: $(du -sh "$DIR" | cut -f1)"
