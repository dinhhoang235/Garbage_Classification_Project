import os
import zipfile

def download_garbage_dataset():
    # 1. Cấu hình tên dataset từ Kaggle
    dataset_name = "sumn2u/garbage-classification-v2"
    
    # 2. Đường dẫn lưu trữ dữ liệu (theo cấu trúc folder đã thống nhất)
    download_path = "data/raw"
    
    # Tạo thư mục nếu chưa tồn tại
    if not os.path.exists(download_path):
        os.makedirs(download_path)
        print(f"Đã tạo thư mục: {download_path}")

    try:
        # 3. Sử dụng Kaggle API để tải xuống
        # Lưu ý: Bạn cần có file kaggle.json trong ~/.kaggle/
        import kaggle
        print("Đang tải dataset từ Kaggle...")
        kaggle.api.dataset_download_files(dataset_name, path=download_path, unzip=True)
        print(f"Tải xuống và giải nén thành công tại: {download_path}")
        
    except Exception as e:
        print(f"Lỗi khi tải dữ liệu: {e}")
        print("Hãy đảm bảo bạn đã cài đặt kaggle API và cấu hình file kaggle.json")

if __name__ == "__main__":
    download_garbage_dataset()