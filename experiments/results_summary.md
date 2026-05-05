# So sánh kết quả experiment

Nguồn dữ liệu: [results_summary.csv](results_summary.csv)

## 1. Tổng quan

| Model                | Test Accuracy | Test F1 Macro | Train Time (s) |     Params |
| -------------------- | ------------: | ------------: | -------------: | ---------: |
| efficientnetv2s      |        0.9130 |        0.9068 |         6560.5 | 20,349,290 |
| mobilenetv3_large    |        0.8920 |        0.8840 |         6717.7 |  3,009,802 |
| mobilenetv1_baseline |        0.8903 |        0.8805 |         5982.2 |  3,243,210 |

## 2. Xếp hạng theo chất lượng

1. `efficientnetv2s`: cao nhất ở cả accuracy và macro F1.
2. `mobilenetv3_large`: đứng thứ hai, khá ổn nhưng thấp hơn một nhịp.
3. `mobilenetv1_baseline`: thấp nhất, hợp lý để làm baseline.

## 3. Phân tích theo từng lớp

### `efficientnetv2s`

- Mạnh ở các lớp `clothes`, `shoes`, `biological`, `battery`.
- Giữ kết quả khá tốt ở `cardboard`, `glass`, `paper`.
- Lớp yếu nhất là `trash`, nhưng vẫn tốt hơn hai model còn lại.

### `mobilenetv3_large`

- Vẫn giữ được chất lượng cao ở `clothes`, `shoes`, `biological`.
- Yếu hơn rõ ở `metal`, `plastic`, `cardboard`, `trash`.
- Đây là model nhẹ hơn nhưng macro F1 bị kéo xuống bởi các lớp khó.

### `mobilenetv1_baseline`

- Tương đối ổn ở `battery`, `biological`, `clothes`, `shoes`.
- Giảm rõ ở `glass`, `paper`, `plastic`, `trash`.
- Là baseline đủ dùng để so sánh, nhưng không phải lựa chọn tốt nhất nếu ưu tiên chất lượng.

## 4. Khác biệt chính giữa các model

### Vì sao `efficientnetv2s` tốt hơn

- Backbone mạnh hơn nên trích xuất đặc trưng tốt hơn.
- Macro F1 cao hơn cho thấy model cân bằng giữa các lớp tốt hơn, không chỉ nhờ các lớp dễ.
- Đổi lại, số tham số lớn hơn nhiều nên model nặng hơn.

### Vì sao MobileNet nhẹ hơn nhưng kém hơn

- `mobilenetv3_large` và `mobilenetv1_baseline` có ít tham số hơn nên gọn hơn.
- Với các lớp gần nhau về hình dạng và màu sắc, backbone nhẹ thường khó tách biên tốt như backbone lớn.
- Điều này thấy rõ ở các lớp dễ nhầm như `trash`, `plastic`, `paper`, `glass`.

### Về thời gian train

- `mobilenetv1_baseline` nhanh nhất.
- `efficientnetv2s` và `mobilenetv3_large` chênh không lớn, nhưng `efficientnetv2s` đổi thêm thời gian để lấy chất lượng tốt hơn.

## 5. Kết luận thực dụng

- Nếu mục tiêu là kết quả tốt nhất, chọn `efficientnetv2s`.
- Nếu cần model nhẹ hơn để triển khai, chọn `mobilenetv3_large`.
- Nếu cần baseline để viết báo cáo hoặc ablation study, giữ `mobilenetv1_baseline`.

## 6. Nhận xét ngắn để đưa vào báo cáo

`efficientnetv2s` cho kết quả tốt nhất trên tập test với accuracy 0.9130 và macro F1 0.9068. MobileNetV3 Large đứng thứ hai nhưng nhẹ hơn nhiều về số tham số. MobileNetV1 Baseline có thời gian train ngắn nhất nhưng chất lượng thấp hơn, đặc biệt ở các lớp khó như trash, plastic, glass và paper.
