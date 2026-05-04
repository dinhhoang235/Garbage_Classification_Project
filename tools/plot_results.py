import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


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

    print(f"Saved plots to {output_dir}")


if __name__ == "__main__":
    main()