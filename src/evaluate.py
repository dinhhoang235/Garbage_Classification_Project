import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix

from preprocessing.generators import get_data_generators


def parse_args():
    """Định nghĩa tham số dòng lệnh cho script đánh giá."""
    parser = argparse.ArgumentParser(description="Evaluate a trained model on the garbage classification test set")
    parser.add_argument("--model_path", type=str, default="models/weights/mobilenet_baseline_best.keras", help="Saved model path")
    parser.add_argument("--base_dir", type=str, default="data/raw/original", help="Root image folder with class subfolders")
    parser.add_argument("--img_size", type=int, nargs=2, default=[224, 224], help="Image size for evaluation")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--train_ratio", type=float, default=0.7, help="Train split ratio")
    parser.add_argument("--val_ratio", type=float, default=0.15, help="Validation split ratio")
    parser.add_argument("--test_ratio", type=float, default=0.15, help="Test split ratio")
    parser.add_argument("--random_state", type=int, default=42, help="Random seed for split")
    parser.add_argument("--confusion_path", type=str, default="reports/confusion_matrix.png", help="Output path for confusion matrix")
    return parser.parse_args()


def plot_confusion_matrix(confusion, labels, output_path):
    """Vẽ và lưu ma trận nhầm lẫn"""
    fig, ax = plt.subplots(figsize=(10, 10))
    im = ax.imshow(confusion, interpolation="nearest", cmap=plt.cm.Blues)
    ax.figure.colorbar(im, ax=ax)
    ax.set(
        xticks=np.arange(confusion.shape[1]),
        yticks=np.arange(confusion.shape[0]),
        xticklabels=labels,
        yticklabels=labels,
        ylabel="True label",
        xlabel="Predicted label",
        title="Confusion Matrix",
    )
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")

    thresh = confusion.max() / 2.0
    for i in range(confusion.shape[0]):
        for j in range(confusion.shape[1]):
            ax.text(j, i, format(confusion[i, j], "d"), ha="center", va="center",
                    color="white" if confusion[i, j] > thresh else "black")

    fig.tight_layout()
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path)
    plt.close(fig)


def main():
    args = parse_args()
    img_size = tuple(args.img_size)

    # Load model đã huấn luyện từ tệp .keras
    model = tf.keras.models.load_model(args.model_path)
    print(f"Loaded model: {args.model_path}")

    # Tạo test generator, không sử dụng data augmentation và không cân bằng
    _, _, test_gen = get_data_generators(
        base_dir=args.base_dir,
        img_size=img_size,
        batch_size=args.batch_size,
        train_ratio=args.train_ratio,
        val_ratio=args.val_ratio,
        test_ratio=args.test_ratio,
        random_state=args.random_state,
        balance_strategy="none",
    )

    print("Evaluating on test set...")
    results = model.evaluate(test_gen, verbose=1)
    loss, accuracy = results[0], results[1]
    print(f"Test loss: {loss:.4f}")
    print(f"Test accuracy: {accuracy:.4f}")

    # Dự đoán nhãn cho toàn bộ test set
    y_true = test_gen.classes
    y_pred_probs = model.predict(test_gen, verbose=1)
    y_pred = np.argmax(y_pred_probs, axis=1)
    labels = list(test_gen.class_indices.keys())

    # In báo cáo phân loại chi tiết
    report = classification_report(y_true, y_pred, target_names=labels, digits=4)
    print("\nClassification report:\n")
    print(report)

    # Vẽ và lưu confusion matrix
    cm = confusion_matrix(y_true, y_pred)
    plot_confusion_matrix(cm, labels, args.confusion_path)
    print(f"Saved confusion matrix to {args.confusion_path}")


if __name__ == "__main__":
    main()
