# Garbage Classification Project

## Giới thiệu

Dự án phân loại rác bằng học sâu. Dữ liệu được tải từ Kaggle và lưu trữ tại thư mục `data/raw`.

## Cài môi trường ảo (venv)

Tạo và kích hoạt `venv` trước khi cài thư viện:

### macOS / Linux

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### Windows (PowerShell)

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

Khi kích hoạt thành công, bạn sẽ thấy tiền tố `(.venv)` ở đầu terminal.

## Yêu cầu

1. Python 3.8+.
2. Cài các thư viện trong `requirements.txt`:

```bash
pip install -r requirements.txt
```

## Hướng dẫn setup dữ liệu Kaggle

### 1. Tạo API Token trên Kaggle

1. Đăng nhập vào tài khoản Kaggle của bạn.
2. Vào **My Account** > **API**.
3. Nhấn **Generate New Token** (API Tokens) để tạo token mới.
4. Sao chép giá trị token từ trang Kaggle.

### 2. Dùng `KAGGLE_API_TOKEN`

1. Thiết lập biến môi trường trong terminal:

```bash
export KAGGLE_API_TOKEN="<your_token_here>"
```

### 3. Tải dữ liệu từ Kaggle

Dự án sử dụng dataset:

- `sumn2u/garbage-classification-v2`

Chạy script tải dữ liệu:

```bash
python src/download_data.py
```

Script này sẽ:

- Tạo thư mục `data/raw` nếu chưa tồn tại
- Tải dataset từ Kaggle
- Giải nén dữ liệu vào `data/raw`

### 4. Kiểm tra dữ liệu

Sau khi tải xong, kiểm tra cấu trúc thư mục:

```bash
find data/raw -maxdepth 2 -type f | head
```

Bạn nên thấy các thư mục class ảnh hoặc file ảnh nằm trong `data/raw`.

## Chạy dự án

Sau khi dữ liệu đã sẵn sàng, bạn có thể sử dụng các module trong `src/` để xử lý, huấn luyện và đánh giá mô hình.

## Tổng quan pipeline

Pipeline tổng của bài gồm ba bước chính:

1. `Tiền xử lý`:
   - Quét dữ liệu ảnh trong `data/raw/original`.
   - Lọc ảnh lỗi, chia tập train/val/test theo stratified split.
   - Tạo train generator với augmentation và val/test generator chỉ rescale.
2. `Huấn luyện`:
   - Dùng `MobileNet` pretrained làm feature extractor (include_top=False).
   - Thêm `GlobalAveragePooling2D` để làm phẳng đặc trưng.
   - Thêm lớp `Dense(num_classes, activation='softmax')` để dự đoán lớp.
   - Huấn luyện model với callback `ModelCheckpoint`, `EarlyStopping`, `CSVLogger`.
3. `Đánh giá`:
   - Dùng test generator để tính `loss` và `accuracy`.
   - In `classification report` và lưu `confusion matrix`.

Sơ đồ tổng quát của pipeline:

`ảnh input -> tiền xử lý -> MobileNet feature extract -> GlobalAveragePooling -> Dense -> Softmax -> nhãn dự đoán`

## Cấu trúc thư mục dự án

Garbage_Classification_Project/
│
├── data/ # Chứa dữ liệu gốc và dữ liệu đã chia tập
│ ├── raw/ # Dữ liệu gốc tải từ Kaggle
│ └── processed/ # Dữ liệu sau khi thực hiện Stratified Split (70/15/15)
│ ├── train/ # 10 thư mục con tương ứng 10 loại rác
│ ├── val/  
│ └── test/  
│
├── notebooks/ # Chứa file Jupyter Notebook để thử nghiệm
│ └── exploration_v1.ipynb # Phân tích dữ liệu và chạy thử tiền xử lý
│
├── models/ # Lưu trữ file model sau khi huấn luyện
│ └── weights/ # Lưu mô hình và trọng số
│
├── src/ # Mã nguồn chính của dự án
│ ├── **init**.py
│ ├── download_data.py # Tải dữ liệu từ Kaggle
│ ├── evaluate.py # Code đánh giá mô hình trên tập Test
│ ├── preprocess.py # Entry point CLI cho tiền xử lý
│ ├── preprocessing/ # Các module tiền xử lý tách nhỏ theo chức năng
│ │ ├── **init**.py
│ │ ├── dataset_io.py # Quét ảnh, lọc ảnh lỗi, lưu split ra thư mục
│ │ ├── splitter.py # Stratified split train/val/test
│ │ ├── generators.py # Tạo train/val/test generators
│ │ ├── reporting.py # Sinh biểu đồ báo cáo tiền xử lý
│ │ └── pipeline.py # Pipeline tổng hợp các bước tiền xử lý
│ ├── train.py # Code xây dựng và huấn luyện MobileNet
│ ├── training/ # Pipeline huấn luyện model
│ │ ├── **init**.py
│ │ └── pipeline.py
│ └── evaluate.py # Code đánh giá mô hình trên tập Test
│
├── app/ # Thư mục triển khai (Deployment)
│ ├── main.py # Code giao diện hoặc API cho User dự đoán ảnh
│ └── templates/ # Giao diện web (nếu có)
│
├── reports/ # Chứa báo cáo và biểu đồ
│ └── confusion_matrix.png # Đánh giá hiệu suất các lớp rác
│
├── requirements.txt # Danh sách thư viện (TensorFlow, Scikit-learn,...)
└── README.md # Hướng dẫn chạy dự án

## Bước 1: Chạy tiền xử lý

Sau khi đã tải dữ liệu và cài thư viện, chạy lệnh sau để:

- Tạo generator train/val/test
- Cân bằng dữ liệu train (mặc định: oversample)
- Sinh báo cáo tiền xử lý trong thư mục `reports/preprocess`
- Lưu dữ liệu đã chia vào `data/processed/train|val|test`
- Lưu thêm báo cáo chữ tiếng Việt tại `reports/preprocess/bao_cao_tien_xu_ly.txt`

```bash
python src/preprocess.py
```

## Pipeline tiền xử lý

Pipeline hiện tại được chạy qua `src/preprocess.py` -> `run_preprocessing_pipeline(...)` trong `src/preprocessing/pipeline.py`, gồm các bước:

1. Quét dữ liệu và lọc ảnh lỗi (`dataset_io.py`).
2. Chia tập train/val/test theo tỉ lệ 70/15/15 bằng stratified split (`splitter.py`).
3. Cân bằng dữ liệu train (`generators.py`):
   - `oversample` (mặc định): tăng mẫu lớp thiểu số bằng lấy mẫu lặp.
   - `class_weight`: giữ nguyên dữ liệu, tính trọng số lớp và gắn vào `train_gen.class_weight`.
   - `none`: không cân bằng.
4. Data augmentation cho train generator (`rotation`, `shift`, `shear`, `zoom`, `horizontal_flip`).
5. Sinh báo cáo tiền xử lý và ảnh minh họa augmentation (`reporting.py`).
6. Tùy chọn lưu dữ liệu đã chia vào `data/processed/train|val|test`.

Sơ đồ ngắn gọn:

`Dataset gốc -> Làm sạch dữ liệu -> Chuẩn hóa/chia train-val-test -> Cân bằng dữ liệu train -> Data Augmentation -> Dataset sau xử lý`

Các cách chạy thường dùng:

```bash
# Mặc định: có cân bằng theo oversample
python src/preprocess.py

# Tắt cân bằng dữ liệu
python src/preprocess.py --balance_strategy none

# Dùng class weight thay cho oversample
python src/preprocess.py --balance_strategy class_weight
```

Nếu bạn không muốn lưu dữ liệu đã chia ra thư mục `data/processed`, dùng cờ `--no_save_split`:

```bash
python src/preprocess.py --no_save_split
```

## Pipeline huấn luyện

Pipeline huấn luyện dùng `src/train.py` và `src/training/pipeline.py`:

1. Tạo generator train/val/test từ `src/preprocessing/generators.py`.
2. Dùng `MobileNet` pretrained làm feature extractor (include_top=False).
3. Thêm `GlobalAveragePooling2D` để làm phẳng đặc trưng.
4. Thêm lớp `Dense(num_classes, activation='softmax')` để dự đoán.
5. Huấn luyện với callback: `ModelCheckpoint`, `EarlyStopping`, `CSVLogger`.
6. Lưu model tốt nhất vào `models/weights/mobilenet_baseline_best.keras`.

Sơ đồ huấn luyện:

`train generator -> MobileNet feature extract -> GlobalAveragePooling -> Dense -> Softmax -> nhãn dự đoán`

Chạy training:

```bash
python src/train.py
```

Hoặc dùng class weight:

```bash
python src/train.py --balance_strategy class_weight --epochs 10
```

## Chạy đánh giá

Dùng `src/evaluate.py` để đánh giá model đã huấn luyện trên test set.

```bash
python src/evaluate.py
```

Nếu muốn chỉ rõ model và file đầu vào:

```bash
python src/evaluate.py --model_path models/weights/mobilenet_baseline_best.keras --base_dir data/raw/original --img_size 224 224 --batch_size 32
```

Kết quả đánh giá sẽ in ra `loss`, `accuracy`, `classification report` và lưu `confusion matrix` tại `reports/confusion_matrix.png`.
