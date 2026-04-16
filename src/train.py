import argparse
from pathlib import Path

from training.pipeline import run_training_pipeline


def parse_args():
    """Định nghĩa các tham số dòng lệnh cho script train."""
    parser = argparse.ArgumentParser(description="Train baseline MobileNet model for garbage classification")
    parser.add_argument("--base_dir", type=str, default="data/raw/original", help="Root image folder with class subfolders")
    parser.add_argument("--img_size", type=int, nargs=2, default=[224, 224], help="Image size for training")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--epochs", type=int, default=10, help="Number of epochs")
    parser.add_argument("--learning_rate", type=float, default=1e-4, help="Adam learning rate")
    parser.add_argument(
        "--balance_strategy",
        type=str,
        default="oversample",
        choices=["none", "oversample", "class_weight"],
        help="Data balancing strategy for training",
    )
    parser.add_argument("--model_dir", type=str, default="models/weights", help="Directory to save trained model")
    parser.add_argument("--history_path", type=str, default="models/weights/train_history.csv", help="CSV path for training history")
    parser.add_argument("--report_path", type=str, default="reports/train/train.txt", help="Text report path for training results")
    parser.add_argument("--trainable", action="store_true", help="Unfreeze MobileNet base and fine-tune")
    parser.add_argument("--validation_split", type=float, default=0.15, help="Validation split ratio")
    parser.add_argument("--test_split", type=float, default=0.15, help="Test split ratio")
    parser.add_argument("--random_state", type=int, default=42, help="Random seed for split")
    return parser.parse_args()


def main():
    # Lấy tham số dòng lệnh
    args = parse_args()
    # Tính tỷ lệ train còn lại khi đã có validation và test
    train_ratio = 1.0 - args.validation_split - args.test_split

    print("Running training pipeline...")
    result = run_training_pipeline(
        base_dir=args.base_dir,
        img_size=tuple(args.img_size),
        batch_size=args.batch_size,
        train_ratio=train_ratio,
        val_ratio=args.validation_split,
        test_ratio=args.test_split,
        random_state=args.random_state,
        balance_strategy=args.balance_strategy,
        epochs=args.epochs,
        learning_rate=args.learning_rate,
        model_dir=args.model_dir,
        history_path=args.history_path,
        trainable=args.trainable,
    )

    # Lấy lịch sử train và đường dẫn model
    history = result["history"]
    checkpoint_path = result["checkpoint_path"]

    # In kết quả của epoch đầu tiên để dễ quan sát
    if history.history.get("loss"):
        print("Initial training metrics:")
        print(f"  loss      = {history.history['loss'][0]:.4f}")
        print(f"  accuracy  = {history.history['accuracy'][0]:.4f}")
        if history.history.get("val_loss"):
            print(f"  val_loss  = {history.history['val_loss'][0]:.4f}")
            print(f"  val_acc   = {history.history['val_accuracy'][0]:.4f}")

    print("Training complete.")
    print(f"Best model saved to: {checkpoint_path}")
    print(f"Training history logged to: {args.history_path}")

    report_path = Path(args.report_path)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_lines = [
        "Training report",
        "================",
        f"Base dir: {args.base_dir}",
        f"Image size: {args.img_size[0]} x {args.img_size[1]}",
        f"Batch size: {args.batch_size}",
        f"Epochs: {args.epochs}",
        f"Learning rate: {args.learning_rate}",
        f"Balance strategy: {args.balance_strategy}",
        f"Trainable base MobileNet: {args.trainable}",
        f"Model saved to: {checkpoint_path}",
        f"Training history CSV: {args.history_path}",
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
    report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    print(f"Training report saved to: {report_path}")


if __name__ == "__main__":
    main()
