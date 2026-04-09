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

## Cấu trúc thư mục dự án
Garbage_Classification_Project/
│
├── data/                       # Chứa dữ liệu gốc và dữ liệu đã chia tập
│   ├── raw/                    # Dữ liệu 13.348 ảnh gốc tải từ Kaggle
│   └── processed/              # Dữ liệu sau khi thực hiện Stratified Split (70/15/15)
│       ├── train/              # 10 thư mục con tương ứng 10 loại rác
│       ├── val/                
│       └── test/               
│
├── notebooks/                  # Chứa file Jupyter Notebook để thử nghiệm
│   └── exploration_v1.ipynb    # Phân tích dữ liệu và chạy thử tiền xử lý
│
├── models/                     # Lưu trữ các file model sau khi huấn luyện
│   ├── weights/                # Lưu trọng số trong quá trình train
│   └── garbage_mobilenet_v1.h5 # Model cuối cùng sau khi "Lưu model"
│
├── src/                        # Mã nguồn chính của dự án
│   ├── __init__.py
│   ├── preprocess.py           # Entry point CLI cho tiền xử lý
│   ├── preprocessing/          # Các module tiền xử lý tách nhỏ theo chức năng
│   │   ├── __init__.py
│   │   ├── dataset_io.py       # Quét ảnh, lọc ảnh lỗi, lưu split ra thư mục
│   │   ├── splitter.py         # Stratified split train/val/test
│   │   ├── generators.py       # Tạo train/val/test generators
│   │   ├── reporting.py        # Sinh biểu đồ báo cáo tiền xử lý
│   │   └── pipeline.py         # Pipeline tổng hợp các bước tiền xử lý
│   ├── train.py                # Code xây dựng và huấn luyện MobileNet
│   └── evaluate.py             # Code đánh giá mô hình trên tập Test
│
├── app/                        # Thư mục triển khai (Deployment)
│   ├── main.py                 # Code giao diện hoặc API cho User dự đoán ảnh
│   └── templates/              # Giao diện web (nếu có)
│
├── reports/                    # Chứa báo cáo và biểu đồ
│   └── confusion_matrix.png    # Đánh giá hiệu suất các lớp rác
│
├── requirements.txt            # Danh sách thư viện (TensorFlow, Scikit-learn,...)
└── README.md                   # Hướng dẫn chạy dự án

## Bước 1: Chạy tiền xử lý
Sau khi đã tải dữ liệu và cài thư viện, chạy lệnh sau để:
- Tạo generator train/val/test
- Sinh báo cáo tiền xử lý trong thư mục `reports/preprocess`
- Lưu dữ liệu đã chia vào `data/processed/train|val|test`
- Lưu thêm báo cáo chữ tiếng Việt tại `reports/preprocess/bao_cao_tien_xu_ly.txt`

```bash
python src/preprocess.py
```

Nếu bạn không muốn lưu dữ liệu đã chia ra thư mục `data/processed`, dùng cờ `--no_save_split`:

```bash
python src/preprocess.py --no_save_split
```