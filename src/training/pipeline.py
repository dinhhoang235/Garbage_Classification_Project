from pathlib import Path

import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks

from preprocessing.generators import get_data_generators


def build_mobilenet_baseline(input_shape, num_classes, trainable=False):
    """Xây model MobileNet baseline với feature extractor và đầu ra softmax."""
    # Tải MobileNet pretrained trên ImageNet, không bao gồm lớp đầu cuối
    base_model = tf.keras.applications.MobileNet(
        input_shape=input_shape,
        include_top=False,
        weights="imagenet",
        pooling=None,
    )
    # Nếu trainable=True thì unfreeze toàn bộ base model để fine-tune
    base_model.trainable = trainable

    # Thêm GlobalAveragePooling để chuyển tensor 3D thành vector
    x = base_model.output
    x = layers.GlobalAveragePooling2D(name="global_average_pooling")(x)
    # Thêm lớp phân loại softmax cho số lớp tương ứng
    outputs = layers.Dense(num_classes, activation="softmax", name="predictions")(x)

    model = models.Model(inputs=base_model.input, outputs=outputs, name="mobilenet_baseline")
    return model


def run_training_pipeline(
    base_dir,
    img_size=(224, 224),
    batch_size=32,
    train_ratio=0.7,
    val_ratio=0.15,
    test_ratio=0.15,
    random_state=42,
    balance_strategy="oversample",
    epochs=10,
    learning_rate=1e-4,
    model_dir="model/weights",
    history_path="model/weights/train_history.csv",
    trainable=False,
):
    """Chạy toàn bộ pipeline huấn luyện: tải dữ liệu, xây model, train và lưu model."""
    img_size = tuple(img_size)
    input_shape = img_size + (3,)

    # Tạo generator train/val/test từ pipeline tiền xử lý
    train_gen, val_gen, test_gen = get_data_generators(
        base_dir=base_dir,
        img_size=img_size,
        batch_size=batch_size,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        random_state=random_state,
        balance_strategy=balance_strategy,
    )

    num_classes = len(train_gen.class_indices)
    model = build_mobilenet_baseline(
        input_shape=input_shape,
        num_classes=num_classes,
        trainable=trainable,
    )
    # Compile model với hàm mất mát categorical_crossentropy và metric accuracy
    model.compile(
        optimizer=optimizers.Adam(learning_rate=learning_rate),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    # Tạo thư mục lưu model và lịch sử nếu chưa tồn tại
    model_dir_path = Path(model_dir)
    model_dir_path.mkdir(parents=True, exist_ok=True)
    checkpoint_path = model_dir_path / "mobilenet_baseline_best.keras"

    # Các callback hỗ trợ training tốt hơn
    callback_list = [
        callbacks.ModelCheckpoint(
            filepath=str(checkpoint_path),
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1,
        ),
        callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=3,
            restore_best_weights=True,
            verbose=1,
        ),
        callbacks.CSVLogger(history_path, append=False),
    ]

    # Huấn luyện model
    history = model.fit(
        train_gen,
        epochs=epochs,
        validation_data=val_gen,
        class_weight=getattr(train_gen, "class_weight", None),
        callbacks=callback_list,
        verbose=1,
    )

    # Lưu model tốt nhất vào đường dẫn checkpoint
    model.save(checkpoint_path)

    return {
        "model": model,
        "history": history,
        "train_generator": train_gen,
        "val_generator": val_gen,
        "test_generator": test_gen,
        "checkpoint_path": str(checkpoint_path),
        "history_path": history_path,
    }
