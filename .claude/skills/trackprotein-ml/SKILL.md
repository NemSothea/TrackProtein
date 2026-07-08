---
name: trackprotein-ml
description: Train, evaluate, export, or integrate TrackProtein's own on-device protein-estimation vision model (Nutrition5k → PyTorch/MPS → Core ML). Use when the user asks to download the dataset, train/retrain the model, run the eval, export the mlpackage, wire up LocalEstimationService, or check training results. Covers everything under ml/.
---

# TrackProtein ML — Own Vision Model

Roadmap, architecture, and ship gates: `ml/PLAN-ML.md` — read it first; it defines which
phase (M1–M6) is active. Run history: `ml/RESULTS.md`. This model **replaces** the Haiku
proxy (`proxy/` is superseded — don't extend it).

## Environment (Python 3.12 via uv — system 3.14 has no torch wheels)
```bash
cd ml
uv venv --python 3.12 .venv                # once
source .venv/bin/activate
uv pip install torch torchvision coremltools pillow pandas
python -c "import torch; print(torch.backends.mps.is_available())"   # must print True
```
`.venv/`, `data/`, `runs/` are gitignored. Never commit dataset images or checkpoints.

## Data (M1)
```bash
./download-data.sh          # full overhead subset (~3.5k dishes, ~2 GB) — resumable, skips existing
python eval.py --baseline   # predict-the-mean MAE: the number every model must beat
```
- Source: `https://storage.googleapis.com/nutrition5k_dataset/nutrition5k_dataset/...`
  (public HTTPS, verified; CC BY 4.0). Labels: `total_protein` = column 6 of
  `dish_metadata_cafe{1,2}.csv` (dish_id is column 1; rows have variable ingredient columns after).
- Splits: official `depth_train_ids.txt` / `depth_test_ids.txt` only. **depth_test is sacred** —
  never train on it, never let augmentation/normalization stats leak from it.

## Train / eval loop (M2–M3)
```bash
python train.py --epochs 30 --res 224            # baseline; checkpoints → runs/<timestamp>/
python eval.py runs/<timestamp>/best.pt          # MAE, range coverage, calibration
```
- Every run — config + test MAE + coverage — gets a row appended to `ml/RESULTS.md`. No exceptions;
  an unlogged run may as well not have happened.
- Quantile head (q10/q50/q90, pinball loss) → maps to app's lowGrams/totalGrams/highGrams.
- Ship gate (M3): MAE ≤ 7 g **and** coverage ≥ 80 % on depth_test.
- MPS quirks: if a training crash mentions an unsupported MPS op, set
  `PYTORCH_ENABLE_MPS_FALLBACK=1` and note the slowdown in RESULTS.md rather than debugging it.

## Export (M4)
```bash
python export_coreml.py runs/<best>/best.pt      # → ProteinEstimator.mlpackage + parity report
```
Parity gate: PyTorch vs Core ML max output diff < 0.5 g over 50 test images; fp16; < 30 MB.
Ask before committing the `.mlpackage` to `TrackProtein/Resources/`.

## App integration (M5)
- New `TrackProtein/Core/Services/LocalEstimationService.swift`: Core ML (lazy-loaded) behind
  the **existing `AIEstimate` struct** — `items: []`, quantiles → low/total/high, confidence
  from interval width. Photo path only (text path is dropped, see PLAN-ML.md).
- AILogView: hide the items list when empty; everything else unchanged.
- Follow CLAUDE.md conventions; verify in Simulator via the `trackprotein-run-sim` skill
  (or the `ios-simulator-verifier` agent) — a real photo must produce a saved
  `ProteinEntry(source: .ai)` with Wi-Fi off.

## Checkpoints
Stop and ask before: deleting `proxy/`, committing the mlpackage, any Swift edit outside
`LocalEstimationService.swift` + `Features/AILogging/`, or lowering the ship gate.
