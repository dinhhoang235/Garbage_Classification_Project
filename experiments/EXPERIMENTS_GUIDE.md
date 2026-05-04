# Hướng dẫn chạy experiments (tổng hợp)

Phần này gộp đầy đủ các bước để chuẩn bị dữ liệu, chạy huấn luyện cho một hoặc nhiều cấu hình, đánh giá và phân tích kết quả.

Lưu ý: hướng dẫn này cũng dùng để train trên Google Colab khi cần GPU nhanh và tiện.

1. Chuẩn bị môi trường & dữ liệu

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/download_data.py    # (nếu chưa có data)
python src/preprocess.py       # tạo các generator và split (70/15/15)
```

2. Chạy huấn luyện

- Single run (chạy từng config, dùng khi debug hoặc chạy thủ công):

```bash
python3 src/train.py --config experiments/configs/mobilenetv3_large.yaml
```

- Batch run (tự động chạy nhiều config và tổng hợp kết quả):

```bash
python3 tools/run_experiments.py --configs \
  experiments/configs/mobilenetv3_large.yaml \
  experiments/configs/efficientnetv2s.yaml \
  experiments/configs/mobilenetv1_baseline.yaml
```

Ghi chú:

- Trong single run bạn có thể override tham số tạm thời:

```bash
python3 src/train.py --config experiments/configs/efficientnetv2s.yaml --epochs 10 --batch_size 16
```

3. Kiểm tra kết quả lưu

```bash
ls -la model/weights/
ls -la experiments/ || true
```

4. Đánh giá model trên tập test (sinh classification report và confusion matrix)

```bash
python3 src/evaluate.py --model_path model/weights/<backbone>_best.keras --base_dir data/raw/original --img_size 224 224 --batch_size 32
```

5. Tổng hợp metrics (nếu dùng batch run sẽ có `experiments/results_summary.csv`)

Nếu chưa có file tổng hợp, thu thập `history`/`metrics`/`classification_report` mà pipeline đã lưu, và tạo `experiments/results_summary.csv` với cột tối thiểu:
`run_id, backbone, test_accuracy, test_f1_macro, train_time_sec, params_count, best_val_accuracy, best_val_loss, model_path`.

6. Vẽ biểu đồ so sánh

```bash
python3 tools/plot_results.py --results_path experiments/results_summary.csv
# outputs -> experiments/plots/
```

7. Phân tích & quyết định bước tiếp theo

- So sánh `test_accuracy` và `test_f1_macro` giữa các model.
- Xem `confusion_matrix` để xác định lớp bị nhầm nhiều.
- Đối chiếu `train_time_sec` và `params_count` để cân bằng hiệu năng/chi phí.

Từ kết quả trên, bạn có thể:

- Fine-tune thêm (tăng `--fine_tune_layers` và huấn luyện với LR nhỏ hơn).
- Thay đổi augmentation, learning rate, batch size và lặp lại.
- Kiểm tra ảnh hưởng của preprocessing bằng cách chạy một nhóm experiment với `preprocessing_function` model-specific.

8. Lưu trữ và báo cáo

Lưu `experiments/results_summary.csv`, `experiments/plots/`, các `classification_report` và `confusion_matrix` vào `reports/` và thêm ghi chú ngắn trong `reports/summary.txt`.

Gợi ý nhanh:

- Bật `EarlyStopping(patience=3-5)` để tránh overfitting và tiết kiệm thời gian.
- Nếu có GPU: bật mixed precision để tăng tốc.
