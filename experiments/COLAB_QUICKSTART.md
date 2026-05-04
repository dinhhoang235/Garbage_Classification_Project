# Google Colab Quickstart — chạy nhanh trên GPU

Tập lệnh này để bạn copy/paste vào một Google Colab notebook (Runtime → Change runtime type → GPU) và chạy thử nhanh.

## 1. Mount Google Drive

```python
from google.colab import drive
drive.mount('/content/drive')
```

## 2. Lấy mã nguồn

```bash
# nếu repo public
!git clone https://github.com/dinhhoang235/Garbage_Classification_Project.git
%cd Garbage_Classification_Project

# nếu private, upload zip vào Drive và unzip
```

## 3. Kiểm tra GPU và cài thư viện

```bash
!nvidia-smi
!pip install -r requirements.txt
```

## 4. Đưa data vào Colab (từ Drive)

```bash
# upoad data vào Drive trước, ví dụ MyDrive/garbage_data
!cp -r /content/drive/MyDrive/garbage_data/ data/raw/
```

## 5. (Tùy) tiền xử lý

```bash
!python3 src/preprocess.py
```

## 6. Chạy training (lưu trực tiếp vào Drive)

```bash
mkdir -p /content/drive/MyDrive/garbage_runs/efficientnetv2s_run1
python3 src/train.py --config experiments/configs/efficientnetv2s.yaml \
  --epochs 10 --batch_size 16 --output_dir /content/drive/MyDrive/garbage_runs/efficientnetv2s_run1
```

Ghi chú:

- Dùng `--epochs 10` để chạy nhanh test; tăng lên 20–30 cho huấn luyện đầy đủ.
- Nếu `train.py` không hỗ trợ `--output_dir`, chạy bình thường rồi copy `model/weights/` về Drive:

```bash
cp -r model/weights /content/drive/MyDrive/garbage_runs/efficientnetv2s_run1/
```

## 7. TensorBoard trong Colab

```python
%load_ext tensorboard
%tensorboard --logdir /content/drive/MyDrive/garbage_runs/ --port 6006
```

## 8. Lưu và tải kết quả về local

```bash
# ví dụ copy toàn bộ run về máy local qua Drive
# (hoặc dùng scp/rsync nếu dùng remote server)
```

## Tips nhanh

- Kiểm tra `!nvidia-smi` để chọn `batch_size` phù hợp.
- Luôn lưu checkpoint và logs vào Drive để tránh mất khi session timeout.
- Colab miễn phí có giới hạn thời gian; dùng Colab Pro khi cần chạy lâu.

---

File này nằm tại `experiments/COLAB_QUICKSTART.md`.
