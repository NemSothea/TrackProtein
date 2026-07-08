"""Conformalize the quantile head (multiplicative CQR): fit one width-scaling factor s so
[q10 - s·w, q90 + s·w] (w = q90 - q10) hits the target coverage on unseen data. MAE is
untouched (q50 as-is), and width-based confidence ranking is preserved (w' = (1+2s)·w).
Multiplicative beats an additive margin here: errors concentrate in wide-interval dishes,
so scaling widens where it's needed instead of taxing every estimate equally.

  python calibrate.py runs/<ts>/best.pt      # writes calibration.json next to best.pt

The factor is fit on the train-carved val split (same seed/carve as train.py), never on
depth_test. eval.py auto-applies calibration.json; export_coreml.py bakes it into the graph.
"""

import argparse
import json
import math
import random
from pathlib import Path

import torch
from torch.utils.data import DataLoader

from dataset import Nutrition5k, split_ids
from train import SEED, build_model


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint", help="runs/<ts>/best.pt")
    ap.add_argument("--res", type=int, default=224)
    ap.add_argument("--alpha", type=float, default=0.05, help="1 - target coverage")
    args = ap.parse_args()

    # Reproduce train.py's carve exactly: same seed, same shuffle, first 10% held out.
    random.seed(SEED)
    ids = split_ids("train")
    random.shuffle(ids)
    cal_ids = ids[: len(ids) // 10]

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    model = build_model().to(device)
    model.load_state_dict(torch.load(args.checkpoint, map_location=device, weights_only=True))
    model.eval()

    loader = DataLoader(
        Nutrition5k(cal_ids, res=args.res, train=False), batch_size=64, num_workers=4
    )
    scores = []
    with torch.no_grad():
        for x, y in loader:
            q = model(x.to(device)).cpu()
            protein = y[:, 0]
            # Width-normalized conformity score: how far the truth falls outside
            # [q10, q90], in units of interval width (negative when inside —
            # those still count toward the quantile).
            w = torch.clamp(q[:, 2] - q[:, 0], min=1e-3)
            scores += (torch.maximum(q[:, 0] - protein, protein - q[:, 2]) / w).tolist()

    scores.sort()
    n = len(scores)
    k = min(math.ceil((n + 1) * (1 - args.alpha)), n) - 1
    scale = max(scores[k], 0.0)

    out = Path(args.checkpoint).parent / "calibration.json"
    out.write_text(
        json.dumps({"scale": round(scale, 4), "alpha": args.alpha, "n_cal": n}) + "\n"
    )
    print(f"n_cal={n}  target coverage {1 - args.alpha:.0%}  width scale {scale:.3f}  → {out}")


if __name__ == "__main__":
    main()
