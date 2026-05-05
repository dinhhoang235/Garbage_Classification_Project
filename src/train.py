import argparse
import json
import shutil
from pathlib import Path

from training.pipeline import run_training_pipeline


def _get_default_base_dir():
    """Autodetect: if data/processed exists with train/val/test, use it; else use data/raw/original."""
    processed_path = Path("data/processed")
    if processed_path.exists() and all(
        (processed_path / split).exists() for split in ["train", "val", "test"]
    ):
        return str(processed_path)
    return "data/raw/original"


def parse_args():
    """Định nghĩa các tham số dòng lệnh cho script train."""
    default_base_dir = _get_default_base_dir()
    
    parser = argparse.ArgumentParser(description="Train garbage classification models")
    parser.add_argument("--config", type=str, default=None, help="Path to a YAML/JSON config file")
    parser.add_argument("--base_dir", type=str, default=default_base_dir, help="Root image folder with class subfolders or pre-split data/processed structure")
    parser.add_argument("--img_size", type=int, nargs=2, default=[224, 224], help="Image size for training")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--epochs", type=int, default=10, help="Number of epochs")
    parser.add_argument("--learning_rate", type=float, default=1e-4, help="Learning rate")
    parser.add_argument("--architecture", type=str, default="MobileNetV1", help="Backbone architecture")
    parser.add_argument("--optimizer", type=str, default="Adam", choices=["Adam", "SGD"], help="Optimizer")
    parser.add_argument("--dropout_rate", type=float, default=0.3, help="Dropout rate in classification head")
    parser.add_argument("--weight_decay", type=float, default=0.0, help="L2 regularization on head")
    parser.add_argument("--fine_tune_layers", type=int, default=0, help="Keep the last N backbone layers trainable")
    parser.add_argument("--mixed_precision", action="store_true", help="Enable mixed precision on supported GPUs")
    parser.add_argument(
        "--balance_strategy",
        type=str,
        default="oversample",
        choices=["none", "oversample", "class_weight"],
        help="Data balancing strategy for training",
    )
    parser.add_argument("--model_dir", type=str, default="model/weights", help="Directory to save trained model")
    parser.add_argument("--history_path", type=str, default="model/weights/train_history.csv", help="CSV path for training history")
    parser.add_argument("--metrics_path", type=str, default="model/weights/metrics_summary.json", help="JSON path for final run metrics")
    parser.add_argument("--classification_report_path", type=str, default="reports/train/classification_report.txt", help="Path to save classification report")
    parser.add_argument("--tensorboard_log_dir", type=str, default=None, help="TensorBoard log directory")
    parser.add_argument("--report_path", type=str, default="reports/train/train.txt", help="Text report path for training results")
    parser.add_argument("--trainable", action="store_true", help="Unfreeze the backbone and fine-tune")
    parser.add_argument("--validation_split", type=float, default=0.15, help="Validation split ratio")
    parser.add_argument("--test_split", type=float, default=0.15, help="Test split ratio")
    parser.add_argument("--random_state", type=int, default=42, help="Random seed for split")
    return parser.parse_args()


def _load_config(path):
    config_path = Path(path)
    if not config_path.exists():
        raise FileNotFoundError(f"Config file not found: {config_path}")

    if config_path.suffix.lower() == ".json":
        return json.loads(config_path.read_text(encoding="utf-8"))

    try:
        import yaml
    except ImportError as exc:  # pragma: no cover - visible in runtime if dependency missing
        raise ImportError("PyYAML is required to load YAML config files") from exc

    return yaml.safe_load(config_path.read_text(encoding="utf-8"))


def main():
    args = parse_args()

    config = _load_config(args.config) if args.config else {}

    def pick(name):
        return config.get(name, getattr(args, name))

    base_dir = pick("base_dir")
    img_size = tuple(pick("img_size"))
    batch_size = pick("batch_size")
    epochs = pick("epochs")
    learning_rate = pick("learning_rate")
    architecture = pick("architecture")
    optimizer_name = pick("optimizer")
    dropout_rate = pick("dropout_rate")
    weight_decay = pick("weight_decay")
    fine_tune_layers = pick("fine_tune_layers")
    mixed_precision = pick("mixed_precision")
    balance_strategy = pick("balance_strategy")
    model_dir = pick("model_dir")
    history_path = pick("history_path")
    metrics_path = pick("metrics_path")
    classification_report_path = pick("classification_report_path")
    tensorboard_log_dir = pick("tensorboard_log_dir")
    report_path = pick("report_path")
    trainable = pick("trainable")
    validation_split = pick("validation_split")
    test_split = pick("test_split")
    random_state = pick("random_state")

    train_ratio = 1.0 - validation_split - test_split

    print(f"Using base_dir: {base_dir}")
    print("Running training pipeline...")
    result = run_training_pipeline(
        base_dir=base_dir,
        img_size=img_size,
        batch_size=batch_size,
        train_ratio=train_ratio,
        val_ratio=validation_split,
        test_ratio=test_split,
        random_state=random_state,
        balance_strategy=balance_strategy,
        epochs=epochs,
        learning_rate=learning_rate,
        architecture=architecture,
        optimizer_name=optimizer_name,
        dropout_rate=dropout_rate,
        weight_decay=weight_decay,
        fine_tune_layers=fine_tune_layers,
        mixed_precision=mixed_precision,
        model_dir=model_dir,
        history_path=history_path,
        metrics_path=metrics_path,
        classification_report_path=classification_report_path,
        tensorboard_log_dir=tensorboard_log_dir,
        trainable=trainable,
    )

    history = result["history"]
    checkpoint_path = result["checkpoint_path"]
    metrics_summary = result.get("metrics_summary", {})

    if history.history.get("loss"):
        print("Initial training metrics:")
        print(f"  loss      = {history.history['loss'][0]:.4f}")
        print(f"  accuracy  = {history.history['accuracy'][0]:.4f}")
        if history.history.get("val_loss"):
            print(f"  val_loss  = {history.history['val_loss'][0]:.4f}")
            print(f"  val_acc   = {history.history['val_accuracy'][0]:.4f}")

    # Copy checkpoint về model/weights/ để tiện evaluate
    default_weights_dir = Path("model/weights")
    default_weights_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_src = Path(checkpoint_path)
    checkpoint_dst = default_weights_dir / checkpoint_src.name
    if checkpoint_src.exists() and checkpoint_src.resolve() != checkpoint_dst.resolve():
        shutil.copy2(checkpoint_src, checkpoint_dst)
        print(f"Checkpoint also copied to: {checkpoint_dst}")

    print("Training complete.")
    print(f"Best model saved to: {checkpoint_path}")
    print(f"Training history logged to: {history_path}")
    print(f"Run metrics saved to: {metrics_path}")
    print(f"Classification report saved to: {classification_report_path}")

    report_path = Path(report_path)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_lines = [
        "Training report",
        "================",
        f"Base dir: {base_dir}",
        f"Architecture: {architecture}",
        f"Image size: {img_size[0]} x {img_size[1]}",
        f"Batch size: {batch_size}",
        f"Epochs: {epochs}",
        f"Learning rate: {learning_rate}",
        f"Optimizer: {optimizer_name}",
        f"Dropout rate: {dropout_rate}",
        f"Weight decay: {weight_decay}",
        f"Fine-tune layers: {fine_tune_layers}",
        f"Mixed precision: {mixed_precision}",
        f"Balance strategy: {balance_strategy}",
        f"Trainable base: {trainable}",
        f"Model saved to: {checkpoint_path}",
        f"Training history CSV: {history_path}",
        f"Metrics summary JSON: {metrics_path}",
        f"Classification report: {classification_report_path}",
        f"TensorBoard log dir: {tensorboard_log_dir}",
    ]
    if history.history.get("loss"):
        report_lines.extend([
            "",
            "Initial training metrics:",
            f"  loss = {history.history['loss'][0]:.4f}",
            f"  accuracy = {history.history['accuracy'][0]:.4f}",
        ])
        if history.history.get("val_loss"):
            report_lines.extend([
                f"  val_loss = {history.history['val_loss'][0]:.4f}",
                f"  val_accuracy = {history.history['val_accuracy'][0]:.4f}",
            ])
    if metrics_summary:
        report_lines.extend([
            "",
            "Final test metrics:",
            f"  test_loss = {metrics_summary.get('test_loss', float('nan')):.4f}",
            f"  test_accuracy = {metrics_summary.get('test_accuracy', float('nan')):.4f}",
            f"  test_f1_macro = {metrics_summary.get('test_f1_macro', float('nan')):.4f}",
            f"  params_count = {metrics_summary.get('params_count', 0)}",
        ])
    report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    print(f"Training report saved to: {report_path}")


if __name__ == "__main__":
    main()