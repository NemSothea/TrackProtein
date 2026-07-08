"""Export a trained checkpoint to Core ML and verify PyTorch↔CoreML parity.

  python export_coreml.py runs/<ts>/best.pt
Produces ProteinEstimator.mlpackage (fp16 mlprogram, iOS 17+) next to this file.
Gates (PLAN-ML.md M4): parity max-diff < 0.5 g over 50 test images; package < 30 MB.
"""

import argparse
import json
import subprocess
from pathlib import Path

import coremltools as ct
import numpy as np
import torch
import torch.nn as nn
from PIL import Image
from torchvision import transforms

from dataset import DATA, IMAGENET_MEAN, IMAGENET_STD, split_ids
from train import build_model

RES = 224  # must match the checkpoint's training resolution
OUT = Path(__file__).parent / "ProteinEstimator.mlpackage"
PARITY_N = 50
PARITY_GATE_G = 0.5
SIZE_GATE_MB = 30


class ExportSafeMacroHead(nn.Module):
    """fp16-safe drop-in for train.MacroHead (same fc weights, same math).

    Core ML's fp16 softplus is the naive log(1+exp(x)), which overflows for x ≳ 11 —
    raw head outputs reach the hundreds, so large predictions collapsed to 0.
    softplus(x) = relu(x) + log1p(exp(-|x|)) is identical but exp never sees a
    positive argument.
    """

    def __init__(self, fc: nn.Linear):
        super().__init__()
        self.fc = fc

    @staticmethod
    def softplus(x: torch.Tensor) -> torch.Tensor:
        return torch.relu(x) + torch.log1p(torch.exp(-torch.abs(x)))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        q50_raw, d_lo, d_hi, fat, carb, cal = self.fc(x).unbind(dim=1)
        q50 = self.softplus(q50_raw)
        lo = torch.clamp(q50 - self.softplus(d_lo), min=0.0)
        hi = q50 + self.softplus(d_hi)
        return torch.stack(
            [lo, q50, hi, self.softplus(fat), self.softplus(carb), self.softplus(cal)], dim=1
        )


class Wrapped(nn.Module):
    """0–1 RGB in → ImageNet-normalize → protein quantiles + macro estimates.

    Normalization lives inside the graph so the app can feed a plain CVPixelBuffer;
    Core ML's ImageType scale=1/255 handles the 0–255 → 0–1 step. The conformal width
    scale (calibration.json) is baked in so the app never sees uncalibrated intervals.
    Outputs: `quantiles` = (q10, q50, q90) protein grams; `macros` = (fat g, carb g, kcal).
    """

    def __init__(self, net: nn.Module, scale: float):
        super().__init__()
        self.net = net
        self.scale = scale
        self.register_buffer("mean", torch.tensor(IMAGENET_MEAN).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor(IMAGENET_STD).view(1, 3, 1, 1))

    def forward(self, x: torch.Tensor) -> tuple[torch.Tensor, torch.Tensor]:
        q = self.net((x - self.mean) / self.std)
        w = q[:, 2:3] - q[:, 0:1]
        lo = torch.clamp(q[:, 0:1] - self.scale * w, min=0.0)
        hi = q[:, 2:3] + self.scale * w
        return torch.cat([lo, q[:, 1:2], hi], dim=1), q[:, 3:6]


def eval_crop(img: Image.Image) -> Image.Image:
    """Same geometry as dataset.make_transform(train=False), kept as PIL for Core ML."""
    resize = transforms.Resize(int(RES * 1.15))
    crop = transforms.CenterCrop(RES)
    return crop(resize(img.convert("RGB")))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint", help="runs/<ts>/best.pt")
    args = ap.parse_args()

    cal_path = Path(args.checkpoint).parent / "calibration.json"
    if not cal_path.exists():
        raise SystemExit(f"{cal_path} missing — run calibrate.py first (intervals must be conformalized before export)")
    scale = json.loads(cal_path.read_text())["scale"]
    print(f"baking CQR width scale {scale:.3f} into the graph")

    net = build_model()
    net.load_state_dict(torch.load(args.checkpoint, map_location="cpu", weights_only=True))
    net.classifier[-1] = ExportSafeMacroHead(net.classifier[-1].fc)
    model = Wrapped(net, scale).eval()

    example = torch.rand(1, 3, RES, RES)
    traced = torch.jit.trace(model, example)

    mlmodel = ct.convert(
        traced,
        inputs=[
            ct.ImageType(
                name="image",
                shape=(1, 3, RES, RES),
                scale=1 / 255.0,
                color_layout=ct.colorlayout.RGB,
            )
        ],
        outputs=[ct.TensorType(name="quantiles"), ct.TensorType(name="macros")],
        minimum_deployment_target=ct.target.iOS17,
        convert_to="mlprogram",
        # fp32, not the default fp16: fp16 accumulation + the baked CQR width scaling
        # puts q90/fat parity at ~0.6–0.8 g (> the 0.5 g gate). fp32 is bit-exact and
        # ~20 MB still clears the < 30 MB size gate.
        compute_precision=ct.precision.FLOAT32,
    )
    mlmodel.short_description = (
        "TrackProtein estimate from an overhead meal photo: protein grams at "
        "q10/q50/q90 (low / best / high) plus fat g / carb g / kcal point estimates."
    )
    mlmodel.save(str(OUT))

    size_mb = int(
        subprocess.run(["du", "-sk", str(OUT)], capture_output=True, text=True).stdout.split()[0]
    ) / 1024
    print(f"saved {OUT.name}  ({size_mb:.1f} MB, gate < {SIZE_GATE_MB})")

    # Parity: identical pre-cropped PIL image through both runtimes, all six outputs.
    test_ids = split_ids("test")[:PARITY_N]
    worst = 0.0
    with torch.no_grad():
        for dish in test_ids:
            pil = eval_crop(Image.open(DATA / "images" / f"{dish}.png"))
            pt_q, pt_m = model(transforms.functional.to_tensor(pil).unsqueeze(0))
            pt = np.concatenate([pt_q.squeeze(0).numpy(), pt_m.squeeze(0).numpy()])
            out = mlmodel.predict({"image": pil})
            cm = np.concatenate([
                np.asarray(out["quantiles"]).reshape(-1),
                np.asarray(out["macros"]).reshape(-1),
            ])
            diffs = np.abs(pt - cm)
            diffs[5] /= 10  # calories are ~10× the gram scale; tolerate 5 kcal, not 0.5
            worst = max(worst, float(np.max(diffs)))
    ok = worst < PARITY_GATE_G and size_mb < SIZE_GATE_MB
    print(f"parity max |diff| over {len(test_ids)} test images: {worst:.3f} g (gate < {PARITY_GATE_G})")
    print("PARITY OK — ready for app integration" if ok else "GATE FAILED — do not ship this export")


if __name__ == "__main__":
    main()
