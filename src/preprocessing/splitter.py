from sklearn.model_selection import train_test_split


def split_dataframe(
    samples_df,
    train_ratio=0.7,
    val_ratio=0.15,
    test_ratio=0.15,
    random_state=42,
):
    """Chia DataFrame theo ti le train/val/test co giu phan bo lop."""
    total_ratio = train_ratio + val_ratio + test_ratio
    if abs(total_ratio - 1.0) > 1e-8:
        raise ValueError("train_ratio + val_ratio + test_ratio phai bang 1.0")

    stratify_col = samples_df["label"] if samples_df["label"].nunique() > 1 else None
    train_df, temp_df = train_test_split(
        samples_df,
        train_size=train_ratio,
        random_state=random_state,
        stratify=stratify_col,
    )

    val_fraction_of_temp = val_ratio / (val_ratio + test_ratio)
    stratify_temp = temp_df["label"] if temp_df["label"].nunique() > 1 else None
    val_df, test_df = train_test_split(
        temp_df,
        train_size=val_fraction_of_temp,
        random_state=random_state,
        stratify=stratify_temp,
    )

    return train_df, val_df, test_df
