from pathlib import Path
import pandas as pd
from tensorflow.keras.preprocessing.image import ImageDataGenerator

from .dataset_io import build_samples_dataframe
from .splitter import split_dataframe


def custom_preprocess_input(image_array):
    """Tien xu ly tu viet: chuyen sang float32 va normalize ve [0, 1]."""
    return image_array.astype("float32") / 255.0


def _is_preprocessed_structure(base_dir):
    """Check if base_dir has pre-split structure: train/, val/, test/ subfolders."""
    base_path = Path(base_dir)
    if not base_path.exists():
        return False
    required_splits = {"train", "val", "test"}
    existing_splits = {d.name for d in base_path.iterdir() if d.is_dir()}
    return required_splits.issubset(existing_splits)


def _build_dataframe_from_split(split_dir, split_name="train"):
    """Build a dataframe by scanning split_dir/<label>/ structure."""
    from .dataset_io import VALID_EXTENSIONS, is_valid_image
    
    split_path = Path(split_dir)
    if not split_path.exists():
        raise FileNotFoundError(f"Split directory not found: {split_dir}")
    
    records = []
    class_dirs = sorted([d for d in split_path.iterdir() if d.is_dir()])
    
    for class_dir in class_dirs:
        label = class_dir.name
        for image_path in class_dir.rglob("*"):
            if not image_path.is_file() or image_path.suffix.lower() not in VALID_EXTENSIONS:
                continue
            if is_valid_image(image_path):
                records.append({"filepath": str(image_path), "label": label})
    
    if not records:
        raise ValueError(f"No valid images found in {split_dir}")
    
    return pd.DataFrame(records)


def _oversample_train_dataframe(train_df, random_state=42):
    """Oversample minority classes in train_df to match the majority class size."""
    if train_df.empty:
        return train_df

    class_counts = train_df["label"].value_counts()
    max_count = int(class_counts.max())

    balanced_parts = []
    for _, group in train_df.groupby("label"):
        if len(group) < max_count:
            sampled = group.sample(n=max_count, replace=True, random_state=random_state)
        else:
            sampled = group
        balanced_parts.append(sampled)

    balanced_df = train_df.iloc[0:0] if not balanced_parts else pd.concat(balanced_parts, ignore_index=True)
    balanced_df = balanced_df.sample(frac=1.0, random_state=random_state).reset_index(drop=True)
    return balanced_df


def _compute_class_weight_dict(labels, class_indices):
    """Compute class weights by inverse frequency: N / (K * n_i)."""
    if len(labels) == 0 or not class_indices:
        return None

    total = len(labels)
    num_classes = len(class_indices)
    counts = labels.value_counts().to_dict()

    class_weight = {}
    for class_name, class_idx in class_indices.items():
        class_count = counts.get(class_name, 0)
        if class_count > 0:
            class_weight[class_idx] = float(total / (num_classes * class_count))

    return class_weight or None


def get_data_generators(
    base_dir,
    img_size=(224, 224),
    batch_size=32,
    train_ratio=0.7,
    val_ratio=0.15,
    test_ratio=0.15,
    random_state=42,
    remove_invalid=False,
    balance_strategy="oversample",
    preprocessing_function=None,
):
    """Tien xu ly du lieu anh va tao 3 generator: train/validation/test.

    If base_dir has pre-split structure (train/, val/, test/ subfolders), loads from there.
    Otherwise, scans base_dir as root with class subfolders and performs stratified split.

    balance_strategy:
        - "none": khong can bang
        - "oversample": oversample cac lop it mau trong train
        - "class_weight": giu nguyen train va tinh class weight (gan vao train_gen.class_weight)

    preprocessing_function:
        - None (default): dung custom_preprocess_input ([0,1] normalization) cho MobileNetV1
        - Truyen backbone preprocess_input cu the (vd: mobilenet_v3.preprocess_input)
          neu backbone co internal preprocessing layers de tranh double-normalize
    """
    if preprocessing_function is None:
        preprocessing_function = custom_preprocess_input
    # Check if base_dir is pre-split (has train/, val/, test/)
    if _is_preprocessed_structure(base_dir):
        base_path = Path(base_dir)
        train_df = _build_dataframe_from_split(str(base_path / "train"), "train")
        val_df = _build_dataframe_from_split(str(base_path / "val"), "val")
        test_df = _build_dataframe_from_split(str(base_path / "test"), "test")
    else:
        # Original behavior: scan base_dir and perform stratified split
        samples_df, _ = build_samples_dataframe(base_dir, remove_invalid=remove_invalid)
        train_df, val_df, test_df = split_dataframe(
            samples_df,
            train_ratio=train_ratio,
            val_ratio=val_ratio,
            test_ratio=test_ratio,
            random_state=random_state,
        )

    original_train_df = train_df
    if balance_strategy == "oversample":
        train_df = _oversample_train_dataframe(train_df, random_state=random_state)
    elif balance_strategy not in {"none", "class_weight"}:
        raise ValueError("balance_strategy must be one of: none, oversample, class_weight")

    datagen_kwargs = {"preprocessing_function": preprocessing_function}

    train_datagen = ImageDataGenerator(
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode="nearest",
        **datagen_kwargs,
    )
    eval_datagen = ImageDataGenerator(**datagen_kwargs)

    train_gen = train_datagen.flow_from_dataframe(
        dataframe=train_df,
        x_col="filepath",
        y_col="label",
        target_size=img_size,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=True,
        seed=random_state,
    )

    if balance_strategy == "class_weight":
        train_gen.class_weight = _compute_class_weight_dict(
            original_train_df["label"], train_gen.class_indices
        )
    else:
        train_gen.class_weight = None

    val_gen = eval_datagen.flow_from_dataframe(
        dataframe=val_df,
        x_col="filepath",
        y_col="label",
        target_size=img_size,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=False,
    )

    test_gen = eval_datagen.flow_from_dataframe(
        dataframe=test_df,
        x_col="filepath",
        y_col="label",
        target_size=img_size,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=False,
    )

    return train_gen, val_gen, test_gen