# 🚀 Phân Tích & Đề Xuất Cải Tiến AI — EcoSort

## 📊 Hiện Trạng Model

| Thông số | Giá trị hiện tại |
|---|---|
| **Architecture** | MobileNet (V1) — pretrained ImageNet |
| **File size** | ~13 MB |
| **Input size** | 224×224 px |
| **Classes** | 10 (battery, biological, cardboard, clothes, glass, metal, paper, plastic, shoes, trash) |
| **Best val_accuracy** | **~88.1%** (epoch 9) |
| **Best val_loss** | **0.360** |
| **Training epochs** | 10 (EarlyStopping patience=3) |
| **Augmentation** | rotation, shift, shear, zoom, horizontal_flip |
| **Balancing** | Oversample minority classes |

---

## 🔍 Điểm Yếu Hiện Tại

### 1. Model Architecture Lỗi Thời
- **MobileNet V1** (2017) đã lỗi thời. MobileNetV2 và V3 cùng kích thước nhưng chính xác hơn ~4–6%
- Chỉ có **GlobalAveragePooling → Dense(softmax)**, không có Dropout → dễ overfit

### 2. Val Accuracy Bị "Trần"
- Val accuracy **88%** dừng lại — chưa fine-tune base model (`trainable=False`)
- Nhiều epoch (~10) nhưng không học feature mới từ domain rác

### 3. Inference Kém Tin Cậy
- Chỉ trả về **top-1 label + confidence**, không có **ngưỡng từ chối** (rejection threshold)
- Nếu confidence < 50% vẫn trả về nhãn → gây nhầm lẫn cho người dùng

### 4. Preprocessing Inference ≠ Training
- Training dùng `ImageDataGenerator` với `rescale=1/255`
- Inference trong `main.py` cũng dùng `/255.0` — nhưng **không áp dụng chuẩn hóa theo mean/std của MobileNet** → mất ~1-2% accuracy

### 5. Không Có Feedback Loop
- Không có cơ chế thu thập ảnh người dùng để **retrain** → model không tự cải thiện theo thời gian

---

## 🎯 Lộ Trình Cải Tiến (Ưu Tiên Cao → Thấp)

### ⚡ Ưu tiên 1: Upgrade lên EfficientNetV2-S / MobileNetV3 (Tác động lớn, dễ làm)

**Dự kiến tăng accuracy: +4–8%**

```python
# Thay MobileNet → EfficientNetV2-S
base_model = tf.keras.applications.EfficientNetV2S(
    input_shape=input_shape,
    include_top=False,
    weights="imagenet",
    pooling=None,
)
# Hoặc MobileNetV3Large (nhẹ hơn, phù hợp mobile)
base_model = tf.keras.applications.MobileNetV3Large(
    input_shape=input_shape,
    include_top=False,
    weights="imagenet",
    pooling=None,
)
```

**Thêm Dropout + BatchNorm vào head:**
```python
x = base_model.output
x = layers.GlobalAveragePooling2D()(x)
x = layers.BatchNormalization()(x)
x = layers.Dropout(0.3)(x)
outputs = layers.Dense(num_classes, activation="softmax")(x)
```

---

### ⚡ Ưu tiên 2: Two-Stage Fine-tuning (Tác động lớn)

**Dự kiến tăng accuracy: +3–5%**

```python
# Stage 1: Train head (5 epochs) — base frozen
base_model.trainable = False
model.fit(train_gen, epochs=5, ...)

# Stage 2: Unfreeze top 30% layers, lr nhỏ hơn 10x
for layer in base_model.layers[-50:]:
    layer.trainable = True
model.compile(optimizer=Adam(lr=1e-5), ...)  # lr nhỏ hơn!
model.fit(train_gen, epochs=15, ...)
```

---

### ⚡ Ưu tiên 3: Fix Preprocessing Inference (Dễ làm ngay)

**Sửa `main.py` để dùng đúng preprocessing của từng model:**

```python
# Hiện tại (sai với MobileNet pretrained):
array = np.asarray(image).astype("float32") / 255.0

# Đúng cho MobileNet/MobileNetV2/V3:
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input
array = preprocess_input(np.asarray(image).astype("float32"))

# Đúng cho EfficientNetV2:
from tensorflow.keras.applications.efficientnet_v2 import preprocess_input
array = preprocess_input(np.asarray(image).astype("float32"))
```

---

### ⚡ Ưu tiên 4: Confidence Threshold + "Unknown" Label

**Cải thiện UX khi model không chắc:**

```python
# main.py - trong /predict endpoint
CONFIDENCE_THRESHOLD = 0.55  # Có thể tune

top_score = float(np.max(predictions))
if top_score < CONFIDENCE_THRESHOLD:
    label = "unknown"
    result["message"] = "Không nhận diện được rác, vui lòng chụp lại rõ hơn"
```

---

### 🔮 Ưu tiên 5: Top-3 Predictions (UX tốt hơn)

```python
# Trả về top-3 thay vì chỉ top-1
top3_indices = np.argsort(predictions)[-3:][::-1]
top3 = [
    {"label": CLASS_NAMES[i], "confidence": float(predictions[i])}
    for i in top3_indices
]
result["top3_predictions"] = top3
```

---

### 🔮 Ưu tiên 6: Learning Rate Scheduling & Mixup Augmentation

```python
# Thêm ReduceLROnPlateau callback
callbacks.ReduceLROnPlateau(
    monitor="val_loss",
    factor=0.5,
    patience=2,
    min_lr=1e-7,
    verbose=1,
),

# Label Smoothing (giảm overconfidence)
model.compile(
    loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.1),
    ...
)
```

---

### 🚀 Ưu tiên 7 (Dài hạn): Continuous Learning Pipeline

Khi người dùng upload nhiều ảnh → thu thập dữ liệu mới:

```
User scans → MinIO storage → Label review (manual/auto) → Retrain trigger
                                      ↓
                              Weekly retrain job → Push new model to server
```

---

## 📈 Tóm Tắt Tác Động Dự Kiến

| Cải tiến | Độ khó | Tăng accuracy | Thời gian |
|---|---|---|---|
| Fix preprocessing inference | ⭐ Dễ | +1-2% | 30 phút |
| Confidence threshold | ⭐ Dễ | UX tốt hơn | 30 phút |
| Top-3 predictions | ⭐ Dễ | UX tốt hơn | 1 giờ |
| Upgrade MobileNetV3 | ⭐⭐ Trung bình | +3-5% | 2-4 giờ train |
| Upgrade EfficientNetV2-S | ⭐⭐ Trung bình | +5-8% | 3-6 giờ train |
| Two-stage fine-tuning | ⭐⭐⭐ Khó | +3-5% thêm | +5-10 giờ train |
| Label Smoothing + LR Schedule | ⭐⭐ Trung bình | +1-2% | 1 giờ |
| Continuous learning pipeline | ⭐⭐⭐⭐ Rất khó | Không giới hạn | Nhiều tuần |

---

## 🏁 Khuyến Nghị Thực Hiện Ngay

1. **Hôm nay**: Fix preprocessing inference (`preprocess_input` thay `/255.0`) + thêm confidence threshold
2. **Tuần này**: Upgrade lên **MobileNetV3Large** (nhẹ hơn EfficientNet, phù hợp deploy) + thêm Dropout head
3. **Tuần sau**: Two-stage fine-tuning + Label Smoothing + ReduceLROnPlateau
4. **Dài hạn**: Thu thập ảnh user → xây pipeline retrain tự động

> [!NOTE]
> Model hiện tại 88% val_accuracy là **khá tốt** cho baseline. Các cải tiến trên có thể đưa lên **92–95%** mà không cần thêm dữ liệu. Nếu có thêm dữ liệu người dùng Việt Nam (ảnh rác thực tế), accuracy có thể lên đến **96–98%**.
