"""Train MobileNetV3-Large + quantile head (q10/q50/q90) on Nutrition5k protein labels.

  python train.py --epochs 30 --res 224
Checkpoints go to runs/<timestamp>/; best.pt is picked by val MAE (10% carved from train —
depth_test stays untouched until eval.py). Appends a summary row to RESULTS.md.
"""

import argparse
import random
import time
from datetime import datetime
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision.models import MobileNet_V3_Large_Weights, mobilenet_v3_large

from dataset import Nutrition5k, split_ids

SEED = 42
QUANTILES = (0.10, 0.50, 0.90)


class MacroHead(nn.Module):
    """Protein quantiles (q50 + softplus offsets so they never cross) plus fat/carb/calorie
    point estimates. Output: (lo, q50, hi, fat, carb, cal), all non-negative."""

    def __init__(self, in_dim: int):
        super().__init__()
        self.fc = nn.Linear(in_dim, 6)  # (q50_raw, d_lo_raw, d_hi_raw, fat_raw, carb_raw, cal_raw)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        q50_raw, d_lo, d_hi, fat, carb, cal = self.fc(x).unbind(dim=1)
        sp = nn.functional.softplus
        q50 = sp(q50_raw)  # grams can't be negative
        lo = torch.clamp(q50 - sp(d_lo), min=0.0)
        hi = q50 + sp(d_hi)
        return torch.stack([lo, q50, hi, sp(fat), sp(carb), sp(cal)], dim=1)


def build_model() -> nn.Module:
    net = mobilenet_v3_large(weights=MobileNet_V3_Large_Weights.IMAGENET1K_V2)
    net.classifier[-1] = MacroHead(net.classifier[-1].in_features)
    return net


def pinball_loss(pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
    losses = []
    for i, q in enumerate(QUANTILES):
        diff = target - pred[:, i]
        losses.append(torch.maximum(q * diff, (q - 1) * diff).mean())
    return sum(losses)


# Aux weights keep protein dominant; calories run ~10× the gram scale, hence 0.02.
AUX_WEIGHTS = ((3, 1, 0.3), (4, 2, 0.3), (5, 3, 0.02))  # (pred col, target col, weight)


def total_loss(pred: torch.Tensor, y: torch.Tensor) -> torch.Tensor:
    loss = pinball_loss(pred[:, :3], y[:, 0])
    for pred_col, target_col, weight in AUX_WEIGHTS:
        loss = loss + weight * (pred[:, pred_col] - y[:, target_col]).abs().mean()
    return loss


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--res", type=int, default=224)
    ap.add_argument("--batch", type=int, default=32)
    ap.add_argument("--lr", type=float, default=3e-4)
    args = ap.parse_args()

    random.seed(SEED)
    torch.manual_seed(SEED)
    device = "mps" if torch.backends.mps.is_available() else "cpu"

    ids = split_ids("train")
    random.shuffle(ids)
    n_val = len(ids) // 10
    val_ids, train_ids = ids[:n_val], ids[n_val:]
    train_dl = DataLoader(
        Nutrition5k(train_ids, args.res, train=True),
        batch_size=args.batch, shuffle=True, num_workers=4, drop_last=True,
    )
    val_dl = DataLoader(Nutrition5k(val_ids, args.res, train=False), batch_size=64, num_workers=4)
    print(f"device={device} train={len(train_ids)} val={len(val_ids)} res={args.res}")

    model = build_model().to(device)
    opt = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=args.epochs)

    run_dir = Path(__file__).parent / "runs" / datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir.mkdir(parents=True)
    best_mae, t0 = float("inf"), time.time()

    for epoch in range(1, args.epochs + 1):
        model.train()
        train_loss = 0.0
        for x, y in train_dl:
            x, y = x.to(device), y.to(device)
            loss = total_loss(model(x), y)
            opt.zero_grad()
            loss.backward()
            opt.step()
            train_loss += loss.item()
        sched.step()

        model.eval()
        abs_err, fat_err, carb_err, covered, n = 0.0, 0.0, 0.0, 0, 0
        with torch.no_grad():
            for x, y in val_dl:
                q = model(x.to(device)).cpu()
                protein = y[:, 0]
                abs_err += (q[:, 1] - protein).abs().sum().item()
                covered += ((q[:, 0] <= protein) & (protein <= q[:, 2])).sum().item()
                fat_err += (q[:, 3] - y[:, 1]).abs().sum().item()
                carb_err += (q[:, 4] - y[:, 2]).abs().sum().item()
                n += len(y)
        val_mae, cov = abs_err / n, covered / n
        marker = ""
        if val_mae < best_mae:  # checkpoint selection stays protein-only (the ship gate)
            best_mae = val_mae
            torch.save(model.state_dict(), run_dir / "best.pt")
            marker = "  ← best"
        print(
            f"epoch {epoch:3d}/{args.epochs}  loss {train_loss / len(train_dl):6.3f}  "
            f"val MAE {val_mae:5.2f} g  cov {cov:5.1%}  "
            f"fat {fat_err / n:5.2f} g  carb {carb_err / n:5.2f} g{marker}"
        )

    mins = (time.time() - t0) / 60
    row = (
        f"| {datetime.now():%Y-%m-%d %H:%M} | {run_dir.name} | mobilenet_v3_large+macro-head "
        f"res={args.res} bs={args.batch} lr={args.lr} ep={args.epochs} | "
        f"{best_mae:.2f} | (val) | {mins:.0f} min |\n"
    )
    with open(Path(__file__).parent / "RESULTS.md", "a") as f:
        f.write(row)
    print(f"\nbest val MAE {best_mae:.2f} g → {run_dir}/best.pt  ({mins:.0f} min)")
    print(f"now run: python eval.py {run_dir.relative_to(Path.cwd())}/best.pt")


if __name__ == "__main__":
    main()
