import argparse
import re
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

try:
    import tensorflow as tf
    from sklearn.metrics import confusion_matrix
    from preprocessing.generators import get_data_generators
except ImportError:  # pragma: no cover - optional if runtime is missing deps
    tf = None
    confusion_matrix = None
    get_data_generators = None


ARCH_PREPROCESSORS = {
    "mobilenet_v1": None,
    "mobilenetv1": None,
    "mobilenet": None,
    "mobilenet_v3_large": None,
    "mobilenetv3_large": None,
    "efficientnet_v2_s": None,
    "efficientnetv2s": None,
}


def _get_preprocess_function(architecture):
    if tf is None:
        return None

    architecture_key = (architecture or "").lower().replace("-", "_")
    if architecture_key in {"mobilenet_v1", "mobilenetv1", "mobilenet"}:
        return tf.keras.applications.mobilenet.preprocess_input
    if architecture_key in {"mobilenet_v3_large", "mobilenetv3_large"}:
        return tf.keras.applications.mobilenet_v3.preprocess_input
    if architecture_key in {"efficientnet_v2_s", "efficientnetv2s"}:
        return tf.keras.applications.efficientnet_v2.preprocess_input
    return None


def _safe_filename(value):
    return re.sub(r"[^A-Za-z0-9._-]+", "_", str(value)).strip("_") or "item"


def _resolve_base_dir(base_dir):
    base_path = Path(base_dir)
    if base_path.exists():
        return base_path

    processed_path = ROOT_DIR / "data" / "processed"
    if processed_path.exists():
        return processed_path

    return base_path


def _load_history(history_path):
    path = Path(history_path)
    if not path.exists():
        return None
    history = pd.read_csv(path)
    if history.empty:
        return None
    if "epoch" not in history.columns:
        history = history.reset_index().rename(columns={"index": "epoch"})
    return history


def _parse_classification_report(report_path):
    path = Path(report_path)
    if not path.exists():
        return None

    rows = []
    pattern = re.compile(r"^(\w+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9]+)$")
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        match = pattern.match(line)
        if not match:
            continue
        label, precision, recall, f1_score, support = match.groups()
        if label in {"accuracy", "macro", "weighted"}:
            continue
        rows.append(
            {
                "label": label,
                "precision": float(precision),
                "recall": float(recall),
                "f1_score": float(f1_score),
                "support": int(support),
            }
        )
    return pd.DataFrame(rows) if rows else None


def _save_lineplot(ax, x, y, label, color=None, linestyle="-"):
    ax.plot(x, y, label=label, color=color, linestyle=linestyle, linewidth=2)


def _plot_metric_curves(results_df, output_dir, metric_name, train_col, val_col, title_prefix, filename):
    valid_rows = []
    for _, row in results_df.sort_values(["test_accuracy", "test_f1_macro"], ascending=False).iterrows():
        run_id = row["run_id"]
        history = _load_history(ROOT_DIR / "runs" / run_id / "history.csv")
        if history is None or train_col not in history.columns or val_col not in history.columns:
            continue
        valid_rows.append((row, history))

    if not valid_rows:
        return

    fig, axes = plt.subplots(len(valid_rows), 1, figsize=(11, 4 * len(valid_rows)), sharex=True)
    if len(valid_rows) == 1:
        axes = [axes]

    for ax, (row, history) in zip(axes, valid_rows):
        epochs = history["epoch"] if "epoch" in history.columns else np.arange(len(history))
        _save_lineplot(ax, epochs, history[train_col], "train", color="#4C72B0")
        _save_lineplot(ax, epochs, history[val_col], "val", color="#C44E52")
        ax.set_title(f"{title_prefix} - {row['run_id']}")
        ax.set_ylabel(metric_name)
        ax.grid(True, alpha=0.25)
        ax.legend()

    axes[-1].set_xlabel("Epoch")
    fig.tight_layout()
    fig.savefig(output_dir / filename, dpi=200)
    plt.close(fig)


def _plot_class_metric_heatmap(results_df, output_dir, metric_name, filename, title):
    class_metric_frames = []
    class_order = []

    for _, row in results_df.iterrows():
        run_id = row["run_id"]
        report = _parse_classification_report(ROOT_DIR / "runs" / run_id / "classification_report.txt")
        if report is None or metric_name not in report.columns:
            continue
        report = report[["label", metric_name]].rename(columns={metric_name: row["architecture"]})
        class_metric_frames.append(report)
        class_order.extend(report["label"].tolist())

    if not class_metric_frames:
        return

    merged = class_metric_frames[0]
    for frame in class_metric_frames[1:]:
        merged = merged.merge(frame, on="label", how="outer")

    class_order = list(dict.fromkeys(class_order))
    merged = merged.set_index("label").reindex(class_order)

    plt.figure(figsize=(10, max(5, 0.5 * len(merged))))
    sns.heatmap(merged, annot=True, fmt=".3f", cmap="YlGnBu", linewidths=0.5, cbar_kws={"label": metric_name})
    plt.title(title)
    plt.ylabel("Class")
    plt.xlabel("Architecture")
    plt.tight_layout()
    plt.savefig(output_dir / filename, dpi=200)
    plt.close()


def _plot_confusion_matrix(cm, labels, output_path, title):
    fig, ax = plt.subplots(figsize=(10, 10))
    im = ax.imshow(cm, interpolation="nearest", cmap=plt.cm.Blues)
    ax.figure.colorbar(im, ax=ax)
    ax.set(
        xticks=np.arange(cm.shape[1]),
        yticks=np.arange(cm.shape[0]),
        xticklabels=labels,
        yticklabels=labels,
        ylabel="True label",
        xlabel="Predicted label",
        title=title,
    )
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")

    thresh = cm.max() / 2.0 if cm.size else 0
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(
                j,
                i,
                format(cm[i, j], "d"),
                ha="center",
                va="center",
                color="white" if cm[i, j] > thresh else "black",
            )

    fig.tight_layout()
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=200)
    plt.close(fig)


def _plot_confusion_matrices(results_df, output_dir, base_dir, img_size=(224, 224), batch_size=32):
    if tf is None or get_data_generators is None or confusion_matrix is None:
        return

    base_path = _resolve_base_dir(base_dir)
    if not base_path.exists():
        return

    confusion_dir = output_dir / "confusion_matrices"
    confusion_dir.mkdir(parents=True, exist_ok=True)

    for _, row in results_df.iterrows():
        model_path = row.get("model_path")
        architecture = row.get("architecture")
        run_id = row.get("run_id")
        if not isinstance(model_path, str) or not model_path:
            continue

        checkpoint_path = (ROOT_DIR / model_path).resolve() if not Path(model_path).is_absolute() else Path(model_path)
        if not checkpoint_path.exists():
            continue

        preprocess_fn = _get_preprocess_function(architecture)
        if preprocess_fn is None:
            continue

        _, _, test_gen = get_data_generators(
            base_dir=str(base_path),
            img_size=img_size,
            batch_size=batch_size,
            train_ratio=0.7,
            val_ratio=0.15,
            test_ratio=0.15,
            random_state=42,
            balance_strategy="none",
            preprocessing_function=preprocess_fn,
        )

        model = tf.keras.models.load_model(checkpoint_path, compile=False)
        test_gen.reset()
        y_true = test_gen.classes
        y_pred_probs = model.predict(test_gen, verbose=0)
        y_pred = np.argmax(y_pred_probs, axis=1)
        labels = [label for label, _ in sorted(test_gen.class_indices.items(), key=lambda item: item[1])]
        cm = confusion_matrix(y_true, y_pred)
        _plot_confusion_matrix(
            cm,
            labels,
            confusion_dir / f"{_safe_filename(run_id)}_confusion_matrix.png",
            f"Confusion Matrix - {run_id}",
        )


def parse_args():
    parser = argparse.ArgumentParser(description="Plot comparison charts from experiment results")
    parser.add_argument(
        "--results_path",
        type=str,
        default="experiments/results_summary.csv",
        help="CSV summary produced by tools/run_experiments.py",
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        default="experiments/plots",
        help="Directory to store charts",
    )
    parser.add_argument(
        "--base_dir",
        type=str,
        default="data/raw/original",
        help="Base directory for generating confusion matrices",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    results_path = Path(args.results_path)
    if not results_path.exists():
        raise FileNotFoundError(f"Results CSV not found: {results_path}")

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(results_path)
    if df.empty:
        raise ValueError("Results CSV is empty")

    if "architecture" not in df.columns and "arch" in df.columns:
        df = df.rename(columns={"arch": "architecture"})

    for metric in ["test_accuracy", "test_f1_macro", "train_time_sec", "params_count"]:
        if metric not in df.columns:
            raise ValueError(f"Missing required metric column: {metric}")

    summary = df.groupby("architecture", as_index=False).agg(
        test_accuracy_mean=("test_accuracy", "mean"),
        test_accuracy_std=("test_accuracy", "std"),
        test_f1_mean=("test_f1_macro", "mean"),
        test_f1_std=("test_f1_macro", "std"),
        train_time_mean=("train_time_sec", "mean"),
        params_mean=("params_count", "mean"),
    )

    plt.figure(figsize=(8, 5))
    sns.barplot(data=summary, x="architecture", y="test_accuracy_mean", color="#4C72B0")
    plt.errorbar(
        x=range(len(summary)),
        y=summary["test_accuracy_mean"],
        yerr=summary["test_accuracy_std"].fillna(0),
        fmt="none",
        ecolor="black",
        capsize=4,
    )
    plt.ylabel("Test Accuracy")
    plt.xlabel("Architecture")
    plt.title("Test Accuracy by Architecture")
    plt.tight_layout()
    plt.savefig(output_dir / "test_accuracy_by_architecture.png", dpi=200)
    plt.close()

    plt.figure(figsize=(8, 5))
    sns.barplot(data=summary, x="architecture", y="test_f1_mean", color="#55A868")
    plt.errorbar(
        x=range(len(summary)),
        y=summary["test_f1_mean"],
        yerr=summary["test_f1_std"].fillna(0),
        fmt="none",
        ecolor="black",
        capsize=4,
    )
    plt.ylabel("Macro F1")
    plt.xlabel("Architecture")
    plt.title("Macro F1 by Architecture")
    plt.tight_layout()
    plt.savefig(output_dir / "test_f1_by_architecture.png", dpi=200)
    plt.close()

    plt.figure(figsize=(8, 5))
    sns.barplot(data=summary, x="architecture", y="train_time_mean", color="#C44E52")
    plt.ylabel("Train Time (sec)")
    plt.xlabel("Architecture")
    plt.title("Average Training Time by Architecture")
    plt.tight_layout()
    plt.savefig(output_dir / "train_time_by_architecture.png", dpi=200)
    plt.close()

    plt.figure(figsize=(8, 5))
    sns.barplot(data=summary, x="architecture", y="params_mean", color="#8172B3")
    plt.ylabel("Parameters")
    plt.xlabel("Architecture")
    plt.title("Average Parameter Count by Architecture")
    plt.tight_layout()
    plt.savefig(output_dir / "params_by_architecture.png", dpi=200)
    plt.close()

    _plot_metric_curves(df, output_dir, "Accuracy", "accuracy", "val_accuracy", "Learning Curves (Accuracy)", "learning_curves_accuracy.png")
    _plot_metric_curves(df, output_dir, "Loss", "loss", "val_loss", "Learning Curves (Loss)", "learning_curves_loss.png")

    _plot_class_metric_heatmap(
        df,
        output_dir,
        "f1_score",
        "class_f1_heatmap.png",
        "Class-wise F1 Score by Architecture",
    )
    _plot_class_metric_heatmap(
        df,
        output_dir,
        "recall",
        "class_recall_heatmap.png",
        "Class-wise Recall by Architecture",
    )

    _plot_confusion_matrices(df, output_dir, args.base_dir)

    print(f"Saved plots to {output_dir}")


if __name__ == "__main__":
    main()