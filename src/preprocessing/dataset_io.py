from pathlib import Path
import shutil

import pandas as pd
from PIL import Image, UnidentifiedImageError

from .splitter import split_dataframe


VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def is_valid_image(image_path):
    """Kiem tra nhanh file anh co doc duoc hay khong."""
    try:
        with Image.open(image_path) as img:
            img.verify()
        return True
    except (UnidentifiedImageError, OSError, ValueError):
        return False


def build_samples_dataframe(base_dir, remove_invalid=False):
    """Quet thu muc du lieu va tao DataFrame gom duong dan anh + nhan."""
    base_path = Path(base_dir)
    if not base_path.exists():
        raise FileNotFoundError(f"Khong tim thay thu muc du lieu: {base_dir}")

    records = []
    invalid_files = []

    class_dirs = sorted([d for d in base_path.iterdir() if d.is_dir()])
    if not class_dirs:
        raise ValueError("Khong tim thay thu muc lop con trong base_dir")

    for class_dir in class_dirs:
        label = class_dir.name
        for image_path in class_dir.rglob("*"):
            if not image_path.is_file() or image_path.suffix.lower() not in VALID_EXTENSIONS:
                continue

            if is_valid_image(image_path):
                records.append({"filepath": str(image_path), "label": label})
            else:
                invalid_files.append(image_path)

    if remove_invalid:
        for bad_file in invalid_files:
            bad_file.unlink(missing_ok=True)

    if not records:
        raise ValueError("Khong co anh hop le de huan luyen")

    samples_df = pd.DataFrame(records)
    return samples_df, invalid_files


def copy_split_images(split_df, split_name, processed_dir):
    """Copy anh cua mot split vao processed_dir/split_name/label."""
    copied_count = 0
    target_root = Path(processed_dir) / split_name

    for _, row in split_df.iterrows():
        source_path = Path(row["filepath"])
        label = row["label"]
        label_dir = target_root / label
        label_dir.mkdir(parents=True, exist_ok=True)

        destination_path = label_dir / source_path.name
        if destination_path.exists():
            stem = source_path.stem
            suffix = source_path.suffix
            index = 1
            while True:
                candidate = label_dir / f"{stem}_{index}{suffix}"
                if not candidate.exists():
                    destination_path = candidate
                    break
                index += 1

        shutil.copy2(source_path, destination_path)
        copied_count += 1

    return copied_count


def save_split_to_directories(
    base_dir,
    processed_dir="data/processed",
    train_ratio=0.7,
    val_ratio=0.15,
    test_ratio=0.15,
    random_state=42,
    remove_invalid=False,
    overwrite_processed=True,
):
    """Luu du lieu da chia thanh cay thu muc: train/val/test/<label>."""
    samples_df, _ = build_samples_dataframe(base_dir, remove_invalid=remove_invalid)
    train_df, val_df, test_df = split_dataframe(
        samples_df,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        random_state=random_state,
    )

    processed_root = Path(processed_dir)
    split_roots = {
        "train": processed_root / "train",
        "val": processed_root / "val",
        "test": processed_root / "test",
    }

    if overwrite_processed:
        for split_path in split_roots.values():
            if split_path.exists():
                shutil.rmtree(split_path)

    processed_root.mkdir(parents=True, exist_ok=True)

    copied_train = copy_split_images(train_df, "train", processed_root)
    copied_val = copy_split_images(val_df, "val", processed_root)
    copied_test = copy_split_images(test_df, "test", processed_root)

    return {
        "processed_dir": str(processed_root),
        "copied_train": int(copied_train),
        "copied_val": int(copied_val),
        "copied_test": int(copied_test),
    }
