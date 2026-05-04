import argparse
import glob
import json
import sys
from pathlib import Path

import pandas as pd

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from training.pipeline import run_training_pipeline


def _load_yaml_config(config_path):
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover - dependency issue will be surfaced to the user
        raise ImportError("PyYAML is required to load experiment config files") from exc

    return yaml.safe_load(Path(config_path).read_text(encoding="utf-8")) or {}


def _normalize_img_size(value):
    if isinstance(value, int):
        return (value, value)
    if isinstance(value, (list, tuple)) and len(value) == 2:
        return tuple(int(item) for item in value)
    raise ValueError(f"Invalid img_size: {value}")


def _resolve_config_paths(patterns):
    config_paths = []
    for pattern in patterns:
        matches = sorted(glob.glob(pattern))
        if matches:
            config_paths.extend(matches)
        else:
            path = Path(pattern)
            if path.exists():
                config_paths.append(str(path))
    unique_paths = []
    seen = set()
    for config_path in config_paths:
        absolute = str(Path(config_path).resolve())
        if absolute not in seen:
            seen.add(absolute)
            unique_paths.append(absolute)
    return unique_paths


def parse_args():
    parser = argparse.ArgumentParser(description="Run and compare multiple training experiments")
    parser.add_argument(
        "--configs",
        nargs="+",
        required=True,
        help="One or more YAML config files or glob patterns",
    )
    parser.add_argument(
        "--results_path",
        type=str,
        default="experiments/results_summary.csv",
        help="CSV file to append summary results",
    )
    return parser.parse_args()


def _validate_data_dir(base_dir):
    """Validate that data directory exists and has class folders."""
    data_path = Path(base_dir)
    if not data_path.exists():
        raise FileNotFoundError(f"Data directory not found: {base_dir}")
    
    class_dirs = [d for d in data_path.iterdir() if d.is_dir()]
    if not class_dirs:
        raise RuntimeError(f"No class folders found in {base_dir}. Found: {list(data_path.iterdir())}")
    
    print(f"  ✓ Data directory valid: {len(class_dirs)} classes found")
    return len(class_dirs)


def main():
    args = parse_args()
    config_paths = _resolve_config_paths(args.configs)
    if not config_paths:
        raise FileNotFoundError("No config files matched the provided patterns")

    print(f"Found {len(config_paths)} config file(s) to run")

    results = []
    results_path = Path(args.results_path)
    results_path.parent.mkdir(parents=True, exist_ok=True)

    for i, config_path in enumerate(config_paths, 1):
        print(f"\n{'='*60}")
        print(f"Experiment {i}/{len(config_paths)}")
        
        try:
            config = _load_yaml_config(config_path)
            experiment_name = config.get("experiment_name") or Path(config_path).stem
            output_dir = Path(config.get("output_dir", f"runs/{experiment_name}"))
            output_dir.mkdir(parents=True, exist_ok=True)

            base_dir = config.get("base_dir", "data/raw/original")
            print(f"Config: {Path(config_path).name}")
            print(f"Experiment: {experiment_name}")
            print(f"Architecture: {config.get('architecture', 'MobileNetV1')}")
            print(f"Base data dir: {base_dir}")
            
            # Validate data directory before running
            _validate_data_dir(base_dir)

            run_kwargs = {
                "base_dir": base_dir,
                "img_size": _normalize_img_size(config.get("img_size", [224, 224])),
                "batch_size": config.get("batch_size", 32),
                "train_ratio": config.get("train_ratio", 0.7),
                "val_ratio": config.get("val_ratio", 0.15),
                "test_ratio": config.get("test_ratio", 0.15),
                "random_state": config.get("random_state", 42),
                "balance_strategy": config.get("balance_strategy", "oversample"),
                "epochs": config.get("epochs", 10),
                "learning_rate": config.get("learning_rate", 1e-4),
                "architecture": config.get("architecture", "MobileNetV1"),
                "optimizer_name": config.get("optimizer", "Adam"),
                "dropout_rate": config.get("dropout_rate", 0.3),
                "weight_decay": config.get("weight_decay", 0.0),
                "fine_tune_layers": config.get("fine_tune_layers", 0),
                "mixed_precision": config.get("mixed_precision", True),
                "trainable": config.get("trainable", False),
                "model_dir": str(output_dir / "checkpoints"),
                "history_path": str(output_dir / "history.csv"),
                "metrics_path": str(output_dir / "metrics_summary.json"),
                "classification_report_path": str(output_dir / "classification_report.txt"),
                "tensorboard_log_dir": str(output_dir / "tensorboard"),
                "report_path": str(output_dir / "train_report.txt"),
            }

            print("Starting training...")
            result = run_training_pipeline(**run_kwargs)
            metrics = result.get("metrics_summary", {})

            row = {
                "experiment_name": experiment_name,
                "config_path": config_path,
                **config,
                **metrics,
            }
            results.append(row)

            interim_df = pd.DataFrame(results)
            interim_df.to_csv(results_path, index=False)
            print(f"✓ Training completed. Results saved to {results_path}")
            
        except Exception as exc:
            print(f"✗ Error running {experiment_name}: {exc}")
            import traceback
            traceback.print_exc()
            raise

    final_df = pd.DataFrame(results)
    final_df.to_csv(results_path, index=False)
    print("\n" + "="*60)
    print("All experiments completed successfully!")
    print(f"Summary CSV: {results_path}")


if __name__ == "__main__":
    main()