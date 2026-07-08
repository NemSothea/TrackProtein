"""Nutrition5k overhead-RGB dataset: images + protein-gram labels, official depth splits."""

from pathlib import Path

import torch
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms

DATA = Path(__file__).parent / "data"
IMAGENET_MEAN, IMAGENET_STD = [0.485, 0.456, 0.406], [0.229, 0.224, 0.225]

# Dishes above this are label noise at TrackProtein's scale (a plate isn't 250 g protein).
MAX_PROTEIN_G = 250.0


def load_labels() -> dict[str, dict[str, float]]:
    """dish_id -> {protein, fat, carb, calories, mass} from both cafe metadata CSVs.

    Row layout: dish_id, total_calories, total_mass, total_fat, total_carb,
    total_protein, then variable per-ingredient columns — we only read the first six.
    """
    labels = {}
    for csv in sorted(DATA.glob("dish_metadata_cafe*.csv")):
        for line in csv.read_text().splitlines():
            f = line.split(",")
            if len(f) < 6 or not f[0].startswith("dish_"):
                continue
            try:
                cal, mass, fat, carb, protein = (float(f[i]) for i in (1, 2, 3, 4, 5))
            except ValueError:
                continue
            if 0.0 <= protein <= MAX_PROTEIN_G and mass > 0 and fat >= 0 and carb >= 0:
                labels[f[0]] = {
                    "protein": protein, "fat": fat, "carb": carb,
                    "calories": cal, "mass": mass,
                }
    return labels


def split_ids(split: str) -> list[str]:
    """Usable dish ids for 'train' or 'test': in the official split, labeled, image on disk."""
    wanted = (DATA / f"depth_{split}_ids.txt").read_text().split()
    labels = load_labels()
    return sorted(i for i in wanted if i in labels and (DATA / "images" / f"{i}.png").exists())


def make_transform(res: int, train: bool) -> transforms.Compose:
    aug = (
        [
            transforms.RandomResizedCrop(res, scale=(0.7, 1.0)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomVerticalFlip(),  # overhead shots have no canonical "up"
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
        ]
        if train
        else [transforms.Resize(int(res * 1.15)), transforms.CenterCrop(res)]
    )
    return transforms.Compose(
        [*aug, transforms.ToTensor(), transforms.Normalize(IMAGENET_MEAN, IMAGENET_STD)]
    )


class Nutrition5k(Dataset):
    def __init__(self, ids: list[str], res: int = 224, train: bool = False):
        self.ids = ids
        self.labels = load_labels()
        self.tf = make_transform(res, train)

    def __len__(self) -> int:
        return len(self.ids)

    def __getitem__(self, idx: int):
        dish = self.ids[idx]
        img = Image.open(DATA / "images" / f"{dish}.png").convert("RGB")
        lab = self.labels[dish]
        target = torch.tensor(
            [lab["protein"], lab["fat"], lab["carb"], lab["calories"]], dtype=torch.float32
        )
        return self.tf(img), target


if __name__ == "__main__":
    labels = load_labels()
    train, test = split_ids("train"), split_ids("test")
    p = sorted(labels[i]["protein"] for i in train)
    print(f"labeled dishes: {len(labels)} | usable train: {len(train)} | usable test: {len(test)}")
    if train:
        print(
            f"train protein g — min {p[0]:.1f} | median {p[len(p) // 2]:.1f} | "
            f"mean {sum(p) / len(p):.1f} | max {p[-1]:.1f}"
        )
