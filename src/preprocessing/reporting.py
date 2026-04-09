from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from PIL import Image
from tensorflow.keras.preprocessing.image import ImageDataGenerator

from .dataset_io import build_samples_dataframe
from .splitter import split_dataframe


def _save_bar_plot(series, title, xlabel, ylabel, output_path):
    plt.figure(figsize=(12, 6))
    series.plot(kind="bar", color="#1f77b4")
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.xticks(rotation=30, ha="right")
    plt.tight_layout()
    plt.savefig(output_path, dpi=180)
    plt.close()


def _save_split_distribution_plot(train_df, val_df, test_df, output_path):
    train_counts = train_df["label"].value_counts().sort_index()
    val_counts = val_df["label"].value_counts().sort_index()
    test_counts = test_df["label"].value_counts().sort_index()

    all_labels = sorted(set(train_counts.index) | set(val_counts.index) | set(test_counts.index))
    plot_df = pd.DataFrame(
        {
            "train": [int(train_counts.get(lbl, 0)) for lbl in all_labels],
            "val": [int(val_counts.get(lbl, 0)) for lbl in all_labels],
            "test": [int(test_counts.get(lbl, 0)) for lbl in all_labels],
        },
        index=all_labels,
    )

    ax = plot_df.plot(kind="bar", figsize=(13, 7), width=0.85)
    ax.set_title("Phân bố mẫu sau khi chia train/val/test")
    ax.set_xlabel("Lớp")
    ax.set_ylabel("Số lượng ảnh")
    ax.legend(title="Tập dữ liệu")
    plt.xticks(rotation=30, ha="right")
    plt.tight_layout()
    plt.savefig(output_path, dpi=180)
    plt.close()


def _save_quality_plot(total_valid, total_invalid, output_path):
    quality_series = pd.Series({"Hợp lệ": total_valid, "Không hợp lệ": total_invalid})
    plt.figure(figsize=(7, 5))
    quality_series.plot(kind="bar", color=["#2ca02c", "#d62728"])
    plt.title("Chất lượng dữ liệu ảnh")
    plt.xlabel("Loại")
    plt.ylabel("Số lượng")
    plt.xticks(rotation=0)
    plt.tight_layout()
    plt.savefig(output_path, dpi=180)
    plt.close()


def _save_augmentation_preview(train_datagen, train_df, output_path, img_size=(224, 224), n_samples=6):
    if train_df.empty:
        return

    preview_df = train_df.sample(min(n_samples, len(train_df)), random_state=42)
    n_cols = len(preview_df)

    _, axes = plt.subplots(2, n_cols, figsize=(3 * n_cols, 6))
    if n_cols == 1:
        axes = np.array(axes).reshape(2, 1)

    for idx, (_, row) in enumerate(preview_df.iterrows()):
        image = Image.open(row["filepath"]).convert("RGB").resize(img_size)
        image_arr = np.array(image)

        augmented = train_datagen.random_transform(image_arr)
        augmented = np.clip(augmented, 0, 255).astype(np.uint8)

        axes[0, idx].imshow(image_arr)
        axes[0, idx].set_title(f"Gốc: {row['label']}")
        axes[0, idx].axis("off")

        axes[1, idx].imshow(augmented)
        axes[1, idx].set_title("Augmented")
        axes[1, idx].axis("off")

    plt.tight_layout()
    plt.savefig(output_path, dpi=180)
    plt.close()


def generate_preprocessing_report(
    base_dir,
    report_dir="reports/preprocess",
    img_size=(224, 224),
    train_ratio=0.7,
    val_ratio=0.15,
    test_ratio=0.15,
    random_state=42,
    remove_invalid=False,
):
    """Sinh báo cáo tiền xử lý dạng ảnh trong thư mục report_dir."""
    report_path = Path(report_dir)
    report_path.mkdir(parents=True, exist_ok=True)

    samples_df, invalid_files = build_samples_dataframe(base_dir, remove_invalid=remove_invalid)
    train_df, val_df, test_df = split_dataframe(
        samples_df,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        random_state=random_state,
    )

    class_distribution_path = report_path / "class_distribution_raw.png"
    split_distribution_path = report_path / "class_distribution_split.png"
    quality_path = report_path / "dataset_quality.png"
    augmentation_preview_path = report_path / "augmentation_preview.png"

    raw_counts = samples_df["label"].value_counts().sort_index()
    _save_bar_plot(
        raw_counts,
        title="Phân bố lớp dữ liệu gốc (sau khi lọc ảnh lỗi)",
        xlabel="Lớp",
        ylabel="Số lượng ảnh",
        output_path=class_distribution_path,
    )
    _save_split_distribution_plot(train_df, val_df, test_df, split_distribution_path)
    _save_quality_plot(total_valid=len(samples_df), total_invalid=len(invalid_files), output_path=quality_path)

    train_datagen = ImageDataGenerator(
        rescale=1.0 / 255,
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode="nearest",
    )
    _save_augmentation_preview(
        train_datagen,
        train_df,
        output_path=augmentation_preview_path,
        img_size=img_size,
    )

    return {
        "total_valid": int(len(samples_df)),
        "total_invalid": int(len(invalid_files)),
        "train_size": int(len(train_df)),
        "val_size": int(len(val_df)),
        "test_size": int(len(test_df)),
        "report_images": [
            str(class_distribution_path),
            str(split_distribution_path),
            str(quality_path),
            str(augmentation_preview_path),
        ],
    }
