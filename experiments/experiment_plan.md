# Kế Hoạch Thí Nghiệm — Điều chỉnh hyperparameter & so sánh kiến trúc

Mục tiêu: tinh chỉnh hyperparameters, thử ít nhất 2 kiến trúc (`MobileNetV3Large`, `EfficientNetV2S`) và so sánh kết quả bằng bảng & biểu đồ; giải thích khác biệt.

## 1. Chuẩn bị (prerequisites)

- Dữ liệu: dùng cùng `data/train`, `data/val`, `data/test` (đảm bảo cùng preprocessing/seed).
- Môi trường: Python + TensorFlow (phiên bản tương thích với EfficientNetV2), `requirements.txt` đã đầy đủ.
- Logging: bật TensorBoard và lưu CSV mỗi run.

## 2. Danh sách thí nghiệm tối thiểu

1. Baseline: hiện tại `MobileNetV1` (file weights hiện có) — giữ để so sánh.
2. `MobileNetV3Large` — mục tiêu: nhanh, phù hợp deploy mobile.
3. `EfficientNetV2S` — mục tiêu: accuracy cao hơn.

Với mỗi kiến trúc thử các biến hyperparam (grid / random):

- learning_rate: [1e-3, 5e-4, 1e-4]
- optimizer: [`Adam`, `SGD` (momentum=0.9)]
- batch_size: [16, 32]
- input_size: [224, 384]
- augmentation: [basic, strong (mixup/cutmix)]
- weight_decay: [0, 1e-4]

Ghi chú: thực hiện ít nhất 3 run ngẫu nhiên mỗi cấu hình để đo phương sai.

## 3. Mẫu config (YAML)

```yaml
experiment_name: mobilenetv3_large_lr1e-4_bs32
architecture: MobileNetV3Large
input_size: 224
batch_size: 32
optimizer: Adam
learning_rate: 1e-4
weight_decay: 0
augmentation: basic
epochs: 50
seed: 42
output_dir: runs/mobilenetv3_large_lr1e-4_bs32
```

## 4. Lệnh chạy (ví dụ)

Sử dụng script wrapper `run_experiments.py` hoặc gọi `src/train.py --config path/to/config.yaml`.

Ví dụ (bash):

```bash
python tools/run_experiments.py --configs experiments/configs/*.yaml
# hoặc chạy 1 config
python src/train.py --config experiments/configs/mobilenetv3_large_lr1e-4_bs32.yaml
```

## 5. Logging & lưu kết quả

- Lưu mỗi run: `config.yaml`, `model_best.h5`, `history.csv` (epoch-wise metrics), `metrics_summary.json` (final metrics), `train.log`.
- Thu thập: `val_accuracy`, `val_loss`, `test_accuracy`, `test_f1_macro`, `params_count`, `train_time`, `inference_latency`.
- Kích hoạt TensorBoard: `tensorboard --logdir runs/`.

## 6. Định dạng bảng kết quả (CSV)

- Cột gợi ý: `experiment,arch,run_id,seed,lr,optimizer,batch,input_size,augment,params,val_acc,val_loss,test_acc,test_f1,train_time`

## 7. Mã mẫu vẽ bảng & biểu đồ (Python)

```python
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

df = pd.read_csv('experiments/results_summary.csv')

# Bar plot: test accuracy per architecture (mean ± std)
agg = df.groupby(['arch'])['test_acc'].agg(['mean','std']).reset_index()
plt.figure(figsize=(6,4))
sns.barplot(x='arch', y='mean', data=agg, yerr=agg['std'])
plt.ylabel('Test Accuracy')
plt.title('Accuracy by Architecture')
plt.tight_layout()
plt.savefig('experiments/plots/arch_accuracy.png')

# Line plots: training curves (example for one run)
history = pd.read_csv('runs/mobilenetv3_large_lr1e-4_bs32/history.csv')
plt.figure()
plt.plot(history['epoch'], history['train_loss'], label='train')
plt.plot(history['epoch'], history['val_loss'], label='val')
plt.legend()
plt.title('Loss Curve')
plt.savefig('experiments/plots/loss_curve_mobilenetv3.png')
```

## 8. Phân tích & giải thích khác biệt (hướng dẫn)

- So sánh accuracy/F1: nếu `EfficientNetV2S` > `MobileNetV3Large`, giải thích bằng capacity (số parameter, receptive field) và khả năng biểu diễn tốt hơn.
- So sánh speed/latency: `MobileNetV3Large` thường có latency thấp hơn — phù hợp deploy trên device.
- Ảnh hưởng input_size: kích thước lớn hơn thường cải thiện accuracy nhưng tăng time/latency.
- Ảnh hưởng augmentation & optimizer: strong augmentation + LR schedule giúp generalize hơn (giảm val gap).
- Kiểm tra overfitting: nếu train_acc >> val_acc → cần regularization (dropout, weight decay) hoặc tăng augmentation.

## 9. Checklist trước khi report

- Đã chạy mỗi config ít nhất 3 lần?
- Đã thu metrics final và lưu vào `experiments/results_summary.csv`?
- Đã tạo bar plots + loss/accuracy curves + confusion matrix cho test set?
- Viết phần giải thích ngắn: nguyên nhân chính, khuyến nghị deploy.

---

Tệp này là template; tôi có thể tiếp tục: (A) tạo `experiments/configs/` mẫu YAML cho từng run, (B) viết `tools/run_experiments.py` để tự động hoá, hoặc (C) chỉnh `src/train.py` để hỗ trợ `--config`. Chọn tiếp theo A/B/C.
