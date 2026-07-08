"""Evaluate on the sacred depth_test split: MAE, range coverage, calibration.

  python eval.py --baseline          # predict-the-train-mean floor: the number to beat
  python eval.py runs/<ts>/best.pt   # evaluate a trained checkpoint
"""

import argparse
import json
import statistics
import sys
from pathlib import Path

import torch
from torch.utils.data import DataLoader

from dataset import Nutrition5k, load_labels, split_ids


def report(name: str, truths, lows, mids, highs) -> None:
    errs = [abs(m - t) for m, t in zip(mids, truths)]
    mae = sum(errs) / len(errs)
    coverage = sum(l <= t <= h for l, t, h in zip(lows, truths, highs)) / len(truths)
    width = sum(h - l for l, h in zip(lows, highs)) / len(lows)
    print(f"\n== {name} on depth_test (n={len(truths)}) ==")
    print(f"MAE            {mae:6.2f} g   (ship gate ≤ 7)")
    print(f"range coverage {coverage:6.1%}    (ship gate ≥ 80%)")
    print(f"median |err|   {statistics.median(errs):6.2f} g")
    print(f"avg interval   {width:6.1f} g wide")


def quantiles(xs, qs):
    xs = sorted(xs)
    return [xs[min(int(q * len(xs)), len(xs) - 1)] for q in qs]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint", nargs="?", help="runs/<ts>/best.pt")
    ap.add_argument("--baseline", action="store_true")
    ap.add_argument("--res", type=int, default=224)
    args = ap.parse_args()

    labels = load_labels()
    test_ids = split_ids("test")
    truths = [labels[i]["protein"] for i in test_ids]

    if args.baseline:
        train_p = [labels[i]["protein"] for i in split_ids("train")]
        mean = sum(train_p) / len(train_p)
        q10, q90 = quantiles(train_p, [0.10, 0.90])
        report(
            "BASELINE predict-train-mean",
            truths,
            [q10] * len(truths),
            [mean] * len(truths),
            [q90] * len(truths),
        )
        return

    if not args.checkpoint:
        sys.exit("pass a checkpoint or --baseline")

    from train import build_model  # noqa: PLC0415 — avoid torch-heavy import for --baseline

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    model = build_model().to(device)
    model.load_state_dict(torch.load(args.checkpoint, map_location=device, weights_only=True))
    model.eval()

    loader = DataLoader(
        Nutrition5k(test_ids, res=args.res, train=False), batch_size=64, num_workers=4
    )
    lows, mids, highs, fats, carbs, cals = [], [], [], [], [], []
    with torch.no_grad():
        for x, _ in loader:
            q = model(x.to(device)).cpu()  # (B, 6) = q10, q50, q90, fat, carb, cal
            lows += q[:, 0].tolist()
            mids += q[:, 1].tolist()
            highs += q[:, 2].tolist()
            fats += q[:, 3].tolist()
            carbs += q[:, 4].tolist()
            cals += q[:, 5].tolist()
    report(f"MODEL {args.checkpoint}", truths, lows, mids, highs)

    for name, preds in [("fat", fats), ("carb", carbs), ("calories", cals)]:
        true = [labels[i][name] for i in test_ids]
        mae = sum(abs(p - t) for p, t in zip(preds, true)) / len(true)
        unit = "kcal" if name == "calories" else "g"
        print(f"  macro {name:8s} MAE {mae:6.2f} {unit}  (display-only, no gate)")

    cal_path = Path(args.checkpoint).parent / "calibration.json"
    if cal_path.exists():
        s = json.loads(cal_path.read_text())["scale"]
        widths = [h - l for l, h in zip(lows, highs)]
        report(
            f"MODEL + CQR width scale {s:.3f}",
            truths,
            [max(l - s * w, 0.0) for l, w in zip(lows, widths)],
            mids,
            [h + s * w for h, w in zip(highs, widths)],
        )
    else:
        print("  (no calibration.json — run calibrate.py to conformalize the intervals)")

    # Calibration: does a narrow interval actually mean a better estimate?
    rows = sorted(zip(lows, mids, highs, truths), key=lambda r: r[2] - r[0])
    third = len(rows) // 3
    for label, chunk in [("high conf (narrow)", rows[:third]), ("low conf (wide)", rows[-third:])]:
        mae = sum(abs(m - t) for _, m, _, t in chunk) / len(chunk)
        print(f"  {label:20s} MAE {mae:5.2f} g")


if __name__ == "__main__":
    main()
