import os
import subprocess

def download_garbage_dataset():
    dataset_name = "sumn2u/garbage-classification-v2"
    download_path = "data/raw"

    if not os.path.exists(download_path):
        os.makedirs(download_path)
        print(f"Đã tạo thư mục: {download_path}")

    try:
        print("Đang tải dataset từ Kaggle (có hiển thị tiến trình)...")

        # Gọi CLI kaggle → có progress bar
        subprocess.run([
            "kaggle", "datasets", "download",
            "-d", dataset_name,
            "-p", download_path,
            "--unzip"
        ], check=True)

        print(f"Tải xuống và giải nén thành công tại: {download_path}")

    except Exception as e:
        print(f"Lỗi khi tải dữ liệu: {e}")
        print("Hãy đảm bảo bạn đã cài đặt kaggle CLI và cấu hình API key")

if __name__ == "__main__":
    download_garbage_dataset()