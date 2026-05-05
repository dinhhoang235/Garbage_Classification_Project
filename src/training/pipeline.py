import json
import time
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks
from sklearn.metrics import classification_report, f1_score

from preprocessing.generators import get_data_generators

# GPU Optimization
try:
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        tf.config.experimental.enable_tensor_float_32_execution(False)
except Exception:
    pass


def _enable_mixed_precision(mixed_precision_mode):
    if not mixed_precision_mode:
        return "float32"

    gpus = tf.config.list_physical_devices("GPU")
    if not gpus:
        return "float32"

    try:
        tf.keras.mixed_precision.set_global_policy("mixed_float16")
        return "mixed_float16"
    except Exception:
        return "float32"


def _get_backbone_spec(architecture):
    architecture_key = architecture.lower().replace("_", "")

    if architecture_key in {"mobilenet", "mobilenetv1"}:
        return {
            "name": "mobilenet_v1",
            "builder": tf.keras.applications.MobileNet,
            # MobileNetV1 expects [-1, 1] — dùng preprocess_input gốc của nó
            "preprocess_input": tf.keras.applications.mobilenet.preprocess_input,
        }

    if architecture_key in {"mobilenetv3large", "mobilenetv3"}:
        return {
            "name": "mobilenet_v3_large",
            "builder": tf.keras.applications.MobileNetV3Large,
            # MobileNetV3 có internal Rescaling layer bên trong model —
            # KHÔNG /255 bên ngoài, chỉ dùng preprocess_input gốc (nhận [0,255])
            "preprocess_input": tf.keras.applications.mobilenet_v3.preprocess_input,
        }

    if architecture_key in {"efficientnetv2", "efficientnetv2s", "efficientnetv2small"}:
        return {
            "name": "efficientnet_v2_s",
            "builder": tf.keras.applications.EfficientNetV2S,
            # EfficientNetV2 cũng có internal normalization — nhận [0,255]
            "preprocess_input": tf.keras.applications.efficientnet_v2.preprocess_input,
        }

    raise ValueError(
        "architecture must be one of: MobileNet, MobileNetV3Large, EfficientNetV2S"
    )


def _build_optimizer(optimizer_name, learning_rate):
    optimizer_key = optimizer_name.lower()
    if optimizer_key == "adam":
        return optimizers.Adam(learning_rate=learning_rate)
    if optimizer_key == "sgd":
        return optimizers.SGD(learning_rate=learning_rate, momentum=0.9)
    raise ValueError("optimizer must be one of: Adam, SGD")


def _build_classification_head(base_output, num_classes, dropout_rate=0.3, weight_decay=0.0):
    x = layers.GlobalAveragePooling2D(name="global_average_pooling")(base_output)
    x = layers.BatchNormalization(name="head_batch_norm")(x)
    if dropout_rate and dropout_rate > 0:
        x = layers.Dropout(dropout_rate, name="head_dropout")(x)
    kernel_regularizer = tf.keras.regularizers.l2(weight_decay) if weight_decay and weight_decay > 0 else None
    outputs = layers.Dense(
        num_classes,
        activation="softmax",
        kernel_regularizer=kernel_regularizer,
        dtype="float32",
        name="predictions",
    )(x)
    return outputs


def build_classification_model(
    architecture,
    input_shape,
    num_classes,
    trainable=False,
    fine_tune_layers=0,
    dropout_rate=0.3,
    weight_decay=0.0,
):
    """Build a pretrained backbone with a lightweight classification head."""
    backbone_spec = _get_backbone_spec(architecture)
    base_model = backbone_spec["builder"](
        input_shape=input_shape,
        include_top=False,
        weights="imagenet",
        pooling=None,
    )

    if trainable and fine_tune_layers > 0:
        base_model.trainable = True
        for layer in base_model.layers[:-fine_tune_layers]:
            layer.trainable = False
    else:
        base_model.trainable = trainable

    outputs = _build_classification_head(
        base_model.output,
        num_classes=num_classes,
        dropout_rate=dropout_rate,
        weight_decay=weight_decay,
    )

    model = models.Model(inputs=base_model.input, outputs=outputs, name=backbone_spec["name"])
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
    architecture="MobileNetV1",
    optimizer_name="Adam",
    dropout_rate=0.3,
    weight_decay=0.0,
    fine_tune_layers=0,
    mixed_precision=True,
    model_dir="model/weights",
    history_path="model/weights/train_history.csv",
    metrics_path="model/weights/metrics_summary.json",
    classification_report_path="reports/train/classification_report.txt",
    tensorboard_log_dir=None,
    trainable=False,
):
    """Chạy toàn bộ pipeline huấn luyện: tải dữ liệu, xây model, train và lưu model."""
    img_size = tuple(img_size)
    input_shape = img_size + (3,)

    # Lấy backbone spec để biết đúng preprocessing function cần dùng
    backbone_spec = _get_backbone_spec(architecture)
    # KEY FIX: mỗi backbone có preprocess_input riêng, KHÔNG hardcode /255
    backbone_preprocess_fn = backbone_spec["preprocess_input"]

    metrics_path = Path(metrics_path)
    classification_report_path = Path(classification_report_path)
    start_time = time.perf_counter()
    precision_policy = _enable_mixed_precision(mixed_precision)

    # Tạo generator train/val/test với đúng preprocessing của backbone
    train_gen, val_gen, test_gen = get_data_generators(
        base_dir=base_dir,
        img_size=img_size,
        batch_size=batch_size,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        random_state=random_state,
        balance_strategy=balance_strategy,
        preprocessing_function=backbone_preprocess_fn,  # FIX: đúng fn cho từng backbone
    )

    num_classes = len(train_gen.class_indices)
    model = build_classification_model(
        architecture=architecture,
        input_shape=input_shape,
        num_classes=num_classes,
        trainable=trainable,
        fine_tune_layers=fine_tune_layers,
        dropout_rate=dropout_rate,
        weight_decay=weight_decay,
    )
    model.compile(
        optimizer=_build_optimizer(optimizer_name, learning_rate),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    model_dir_path = Path(model_dir)
    model_dir_path.mkdir(parents=True, exist_ok=True)
    checkpoint_path = model_dir_path / f"{backbone_spec['name']}_best.keras"

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
    if tensorboard_log_dir:
        callback_list.append(
            callbacks.TensorBoard(
                log_dir=str(tensorboard_log_dir),
                histogram_freq=0,
                write_graph=True,
            )
        )

    history = model.fit(
        train_gen,
        epochs=epochs,
        validation_data=val_gen,
        class_weight=getattr(train_gen, "class_weight", None),
        callbacks=callback_list,
        verbose=1,
    )

    model.save(checkpoint_path)

    test_gen.reset()
    test_loss, test_accuracy = model.evaluate(test_gen, verbose=1)
    test_gen.reset()
    y_true = test_gen.classes
    y_pred_probs = model.predict(test_gen, verbose=1)
    y_pred = np.argmax(y_pred_probs, axis=1)
    test_f1_macro = f1_score(y_true, y_pred, average="macro")
    class_labels = [label for label, _ in sorted(test_gen.class_indices.items(), key=lambda item: item[1])]
    classification_text = classification_report(y_true, y_pred, target_names=class_labels, digits=4)

    total_time = time.perf_counter() - start_time
    best_val_accuracy = float(max(history.history["val_accuracy"])) if history.history.get("val_accuracy") else None
    best_val_loss = float(min(history.history["val_loss"])) if history.history.get("val_loss") else None

    metrics_summary = {
        "architecture": backbone_spec["name"],
        "base_dir": base_dir,
        "img_size": list(img_size),
        "batch_size": batch_size,
        "epochs": epochs,
        "learning_rate": learning_rate,
        "optimizer": optimizer_name,
        "dropout_rate": dropout_rate,
        "weight_decay": weight_decay,
        "fine_tune_layers": fine_tune_layers,
        "mixed_precision": mixed_precision,
        "precision_policy": precision_policy,
        "balance_strategy": balance_strategy,
        "trainable": trainable,
        "train_accuracy": float(history.history["accuracy"][-1]),
        "val_accuracy": float(history.history["val_accuracy"][-1]),
        "best_val_accuracy": best_val_accuracy,
        "train_loss": float(history.history["loss"][-1]),
        "val_loss": float(history.history["val_loss"][-1]),
        "best_val_loss": best_val_loss,
        "test_loss": float(test_loss),
        "test_accuracy": float(test_accuracy),
        "test_f1_macro": float(test_f1_macro),
        "params_count": int(model.count_params()),
        "train_time_sec": float(total_time),
        "checkpoint_path": str(checkpoint_path),
        "history_path": str(history_path),
    }

    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(json.dumps(metrics_summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    classification_report_path.parent.mkdir(parents=True, exist_ok=True)
    classification_report_path.write_text(classification_text + "\n", encoding="utf-8")

    return {
        "model": model,
        "history": history,
        "train_generator": train_gen,
        "val_generator": val_gen,
        "test_generator": test_gen,
        "checkpoint_path": str(checkpoint_path),
        "history_path": history_path,
        "metrics_path": str(metrics_path),
        "classification_report_path": str(classification_report_path),
        "metrics_summary": metrics_summary,
    }