import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator

def get_data_generators(base_dir, img_size=(224, 224), batch_size=32):
    """
    Hàm thực hiện tiền xử lý và tạo generator cho dữ liệu.
    Giải quyết: Chuẩn hóa, Data Augmentation và Chia tập dữ liệu.
    """
    
    # 1. Định nghĩa Augmentation cho tập Train (Giải quyết Background phức tạp)
    train_datagen = ImageDataGenerator(
        rescale=1./255,               # Chuẩn hóa pixel
        rotation_range=30,            # Xoay ảnh
        width_shift_range=0.2,
        height_shift_size=0.2,
        shear_range=0.2,
        zoom_range=0.2,               # Phóng to/nhỏ
        horizontal_flip=True,         # Lật ảnh
        fill_mode='nearest',
        validation_split=0.3          # Chia 30% cho Val/Test từ data gốc
    )

    # 2. Định nghĩa Rescale cho tập Validation/Test
    test_val_datagen = ImageDataGenerator(rescale=1./255)

    # 3. Tạo các Generator (Tương ứng bước Chia tập dữ liệu trong Pipeline)
    train_gen = train_datagen.flow_from_directory(
        base_dir,
        target_size=img_size,         # Resize về 224x224
        batch_size=batch_size,
        class_mode='categorical',
        subset='training'
    )

    # Lưu ý: Các tập Val/Test sẽ được lấy từ phần còn lại (tùy thuộc vào cấu trúc folder thực tế)
    return train_gen