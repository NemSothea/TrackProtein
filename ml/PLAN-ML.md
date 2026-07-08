# TrackProtein — Own Vision Model (Nutrition5k → Core ML)

**Decision (2026-07-02):** build our own protein-estimation vision model, trained on Nutrition5k,
shipped on-device via Core ML. It **replaces** the Claude/Haiku proxy entirely — fully offline,
private, zero API cost. `proxy/` and `PLAN-PROXY.md` are **superseded** (kept in the repo as
reference until M5 removes the app's dependency on them).

**Product consequences accepted with this decision:**
- v1 output is **total protein grams + low–high range + confidence** — no per-item breakdown
  (`AIEstimate.items` will be empty). Itemization = possible v2 (ingredient-recognition head).
- Natural-language logging (PLAN.md F16, "2 eggs and a shake") is **dropped** — no local model
  for that; manual quick-add covers it.
- "AI photo logging" can stay premium (StoreKit-gated in-app) even though inference is free.

**Rig:** Apple M3, macOS 26.5, PyTorch on MPS. Python via `uv`-pinned **3.12** venv
(system Python is 3.14 — too new for torch wheels). ~2 GB data on disk (46 GB free).

---

## Architecture (v1 — deliberately boring)

- **Backbone:** `torchvision` MobileNetV3-Large, ImageNet-pretrained (~5.4 M params → ~11 MB
  fp16 `.mlpackage`; fast on-device, converts cleanly to Core ML). No timm, no exotic deps.
- **Head:** quantile regression, 3 outputs = protein at q0.10 / q0.50 / q0.90
  (pinball loss). Maps directly onto the app's existing `lowGrams / totalGrams / highGrams`;
  `confidence` derives from interval width (narrow → high). Aux heads for total mass +
  calories (small loss weight) — known to stabilize nutrient regression; try in M3 if the
  plain head underperforms.
- **Input:** overhead RGB, 384×384 (train at 224 first for speed, bump if accuracy needs it).
- **Data:** Nutrition5k `realsense_overhead` RGB frames (~3.5 k dishes, CC BY 4.0) +
  `dish_metadata_cafe{1,2}.csv` protein labels. **Official `depth_train` / `depth_test` splits —
  never train on test.** Same test set + metrics as the old proxy eval, so any future
  comparison is apples-to-apples.

## Phases

| # | What | Done when | Effort |
|---|---|---|---|
| M1 | **Data**: download overhead RGB subset + metadata + splits (HTTPS, verified public); loader + label sanity checks (distribution, outliers, missing images) | `ml/eval.py --baseline` prints the predict-the-mean MAE (the number to beat) | ~0.5 day |
| M2 | **Baseline model**: uv venv (py 3.12, torch/MPS, coremltools, pillow, pandas); train MobileNetV3 + quantile head; eval on depth_test | Test MAE **clearly** beats mean-baseline; range coverage (truth ∈ [q10, q90]) ≥ 70 % | ~1–2 days |
| M3 | **Iterate**: augmentation (flips/rotations/color jitter), 384 px, aux mass+calorie heads, LR/schedule sweeps — every run logged to `ml/RESULTS.md` | Ship gate: **MAE ≤ 7 g and coverage ≥ 80 %** on depth_test (revisit gate if plateau — with data this size, plateau is possible) | ~2–5 days |
| M4 | **Core ML export**: `coremltools` → fp16 `.mlpackage`; parity check (PyTorch vs Core ML outputs agree within tolerance on 50 test images) | Parity max-diff < 0.5 g; model < 30 MB | ~0.5 day |
| M5 | **App integration**: `LocalEstimationService` returning the existing `AIEstimate` struct (empty `items`); AILogView displays total+range (hide items list for this source); photo path only; remove proxy config; verify in Simulator | Photo → saved `ProteinEntry(source: .ai)` with no network; existing unit-test suite still green | ~1 day |
| M6 | **Reality check** (honest gate): 15–20 photos of *your real meals* with protein computed from labels/USDA; measure domain shift vs rig imagery | Real-photo MAE within ~1.5× of test-set MAE → ship. Much worse → M3 with augmentation targeted at phone-photo conditions | ~0.5 day |

## Layout

```
ml/
├── PLAN-ML.md            ← this file
├── RESULTS.md            ← every training/eval run: date, config, MAE, coverage
├── download-data.sh      ← full overhead subset (adapts proxy/eval/download-data.sh)
├── dataset.py            ← csv → (image, protein[, mass, cal]) samples, official splits
├── train.py              ← args: --epochs --lr --res --aux; checkpoints → runs/
├── eval.py               ← MAE + coverage + calibration on depth_test; --baseline flag
├── export_coreml.py      ← best checkpoint → ProteinEstimator.mlpackage + parity check
├── data/                 ← gitignored (~2 GB)
└── runs/                 ← gitignored checkpoints
```
Final `.mlpackage` is committed to `TrackProtein/Resources/` (app needs it; ~11 MB is fine).

## Rules

- Reproducibility: fixed seed per run; every run appends config + metrics to `ml/RESULTS.md`.
- `depth_test` is sacred — no training, no hyperparameter picking against it more than the
  logged M3 iterations; M6's real photos are the true holdout.
- No new Swift dependencies — Core ML + Vision are built-in. Model loads lazily (don't slow launch).
- Stop-and-ask before: committing the `.mlpackage`, deleting `proxy/`, touching any Swift file
  outside `LocalEstimationService` + the AILogging feature folder.
