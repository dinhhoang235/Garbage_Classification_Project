import argparse
from pathlib import Path

from preprocessing.pipeline import run_preprocessing_pipeline


def _build_arg_parser():
    parser = argparse.ArgumentParser(description="Tien xu ly du lieu va sinh bao cao anh")
    parser.add_argument(
        "--base_dir",
        type=str,
        default="data/raw/original",
        help="Thu muc du lieu goc theo cau truc class folders",
    )
    parser.add_argument("--report_dir", type=str, default="reports/preprocess", help="Thu muc luu bao cao anh")
    parser.add_argument("--img_size", type=int, nargs=2, default=[224, 224], help="Kich thuoc resize")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--train_ratio", type=float, default=0.7)
    parser.add_argument("--val_ratio", type=float, default=0.15)
    parser.add_argument("--test_ratio", type=float, default=0.15)
    parser.add_argument("--random_state", type=int, default=42)
    parser.add_argument(
        "--processed_dir",
        type=str,
        default="data/processed",
        help="Thu muc luu du lieu da chia train/val/test",
    )
    parser.add_argument(
        "--no_save_split",
        action="store_true",
        help="Khong luu anh da chia ra data/processed/train|val|test",
    )
    parser.add_argument(
        "--no_overwrite_processed",
        action="store_true",
        help="Khong xoa du lieu cu trong processed truoc khi copy",
    )
    parser.add_argument(
        "--remove_invalid",
        action="store_true",
        help="Xoa cac file anh loi khoi o dia khi quet du lieu",
    )
    return parser


def main():
    args = _build_arg_parser().parse_args()

    train_gen, val_gen, test_gen, report_info, split_info = run_preprocessing_pipeline(
        base_dir=args.base_dir,
        report_dir=args.report_dir,
        processed_dir=args.processed_dir,
        img_size=tuple(args.img_size),
        batch_size=args.batch_size,
        train_ratio=args.train_ratio,
        val_ratio=args.val_ratio,
        test_ratio=args.test_ratio,
        random_state=args.random_state,
        remove_invalid=args.remove_invalid,
        save_split=not args.no_save_split,
        overwrite_processed=not args.no_overwrite_processed,
    )

    txt_report_path = Path(args.report_dir) / "bao_cao_tien_xu_ly.txt"
    train_num_classes = len(getattr(train_gen, "class_indices", {}))
    val_num_classes = len(getattr(val_gen, "class_indices", {}))
    test_num_classes = len(getattr(test_gen, "class_indices", {}))

    summary_lines = [
        "=== BÁO CÁO TIỀN XỬ LÝ (TIẾNG VIỆT) ===",
        f"Tìm thấy {train_gen.samples} ảnh hợp lệ thuộc {train_num_classes} lớp cho tập train.",
        f"Tìm thấy {val_gen.samples} ảnh hợp lệ thuộc {val_num_classes} lớp cho tập validation.",
        f"Tìm thấy {test_gen.samples} ảnh hợp lệ thuộc {test_num_classes} lớp cho tập test.",
        "=== TÓM TẮT ===",
        f"Tổng ảnh hợp lệ : {report_info['total_valid']}",
        f"Tổng ảnh lỗi    : {report_info['total_invalid']}",
        f"Kích thước train: {report_info['train_size']}",
        f"Kích thước val  : {report_info['val_size']}",
        f"Kích thước test : {report_info['test_size']}",
        "Ảnh báo cáo đã tạo:",
    ]
    summary_lines.extend([f"- {image_path}" for image_path in report_info["report_images"]])

    if split_info is not None:
        summary_lines.extend(
            [
                "=== DỮ LIỆU ĐÃ CHIA VÀ LƯU RA THƯ MỤC ===",
                f"Thư mục lưu   : {split_info['processed_dir']}",
                f"Số ảnh train  : {split_info['copied_train']}",
                f"Số ảnh val    : {split_info['copied_val']}",
                f"Số ảnh test   : {split_info['copied_test']}",
            ]
        )

    txt_report_path.parent.mkdir(parents=True, exist_ok=True)
    txt_report_path.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print("=== PREPROCESSING REPORT SUMMARY ===")
    print(f"Valid images   : {report_info['total_valid']}")
    print(f"Invalid images : {report_info['total_invalid']}")
    print(f"Train size     : {report_info['train_size']}")
    print(f"Val size       : {report_info['val_size']}")
    print(f"Test size      : {report_info['test_size']}")
    print("Generated report images:")
    for image_path in report_info["report_images"]:
        print(f"- {image_path}")

    if split_info is not None:
        print("=== SAVED SPLIT DATA ===")
        print(f"Processed dir  : {split_info['processed_dir']}")
        print(f"Copied train   : {split_info['copied_train']}")
        print(f"Copied val     : {split_info['copied_val']}")
        print(f"Copied test    : {split_info['copied_test']}")

    print(f"Vietnamese TXT report: {txt_report_path}")


if __name__ == "__main__":
    main()