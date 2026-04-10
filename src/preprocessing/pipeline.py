from .dataset_io import save_split_to_directories
from .generators import get_data_generators
from .reporting import generate_preprocessing_report


def run_preprocessing_pipeline(
    base_dir,
    report_dir="reports/preprocess",
    processed_dir="data/processed",
    img_size=(224, 224),
    batch_size=32,
    train_ratio=0.7,
    val_ratio=0.15,
    test_ratio=0.15,
    random_state=42,
    remove_invalid=False,
    save_split=False,
    overwrite_processed=True,
    balance_strategy="oversample",
):
    """Chay day du tien xu ly: tao generator, sinh bao cao va luu split tuy chon."""
    train_gen, val_gen, test_gen = get_data_generators(
        base_dir=base_dir,
        img_size=img_size,
        batch_size=batch_size,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        random_state=random_state,
        remove_invalid=remove_invalid,
        balance_strategy=balance_strategy,
    )

    report_summary = generate_preprocessing_report(
        base_dir=base_dir,
        report_dir=report_dir,
        img_size=img_size,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        random_state=random_state,
        remove_invalid=remove_invalid,
    )

    split_summary = None
    if save_split:
        split_summary = save_split_to_directories(
            base_dir=base_dir,
            processed_dir=processed_dir,
            train_ratio=train_ratio,
            val_ratio=val_ratio,
            test_ratio=test_ratio,
            random_state=random_state,
            remove_invalid=remove_invalid,
            overwrite_processed=overwrite_processed,
        )

    return train_gen, val_gen, test_gen, report_summary, split_summary
