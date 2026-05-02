import io
from pathlib import Path
from typing import Dict

import numpy as np
import tensorflow as tf
from fastapi import Depends, FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import settings
from app.core.database import engine, get_db, Base
from app.core.storage import init_minio, upload_image_to_minio
from app.core.seed import seed_categories, seed_notifications
from app.routers import auth, users, categories, history, notifications

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Garbage Classification API",
    description="FastAPI backend để nhận ảnh, chạy model Keras và trả nhãn rác.",
    version="1.0.0",
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(categories.router)
app.include_router(history.router)
app.include_router(notifications.router)

CLASS_NAMES = [
    "battery",
    "biological",
    "cardboard",
    "clothes",
    "glass",
    "metal",
    "paper",
    "plastic",
    "shoes",
    "trash",
]

MODEL_PATH = settings.model_path
model = None


def load_model() -> tf.keras.Model:
    global model
    if model is None:
        if not Path(MODEL_PATH).is_file():
            raise RuntimeError(f"Model file not found at {MODEL_PATH}")
        model = tf.keras.models.load_model(MODEL_PATH)
    return model


@app.on_event("startup")
def startup_event() -> None:
    load_model()
    init_minio()
    seed_categories()
    seed_notifications()


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    loaded = load_model()
    input_shape = loaded.input_shape

    if not input_shape or len(input_shape) != 4:
        raise ValueError("Model input shape phải có dạng (None, height, width, channels)")

    _, height, width, channels = input_shape
    if channels not in (1, 3):
        raise ValueError("Model chỉ hỗ trợ 1 hoặc 3 channel ảnh")

    image = image.resize((width, height))
    array = np.asarray(image).astype("float32") / 255.0
    if array.ndim == 2:
        array = np.stack([array] * channels, axis=-1)
    if array.shape[-1] != channels:
        raise ValueError("Kích thước kênh ảnh không đúng với model")
    return np.expand_dims(array, axis=0)


@app.get("/")
def read_root() -> Dict[str, str]:
    return {"message": "Garbage Classification FastAPI is running"}


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/db-health")
def db_health() -> Dict[str, str]:
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except SQLAlchemyError:
        raise HTTPException(status_code=503, detail="Cannot connect to MySQL database")
    return {"status": "ok", "database": "connected"}


@app.post("/predict")
async def predict(file: UploadFile = File(...), db=Depends(get_db)) -> JSONResponse:
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Chỉ chấp nhận file ảnh")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="File ảnh trống")

    try:
        data = preprocess_image(image_bytes)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    # Upload to MinIO
    image_url = upload_image_to_minio(image_bytes, file.content_type)

    predictions = load_model().predict(data)
    if predictions.ndim == 2:
        predictions = predictions[0]

    top_index = int(np.argmax(predictions))
    top_score = float(np.max(predictions))
    label = CLASS_NAMES[top_index]
    
    from app.models.category import WasteCategory
    category = db.query(WasteCategory).filter(WasteCategory.id == label).first()
    category_data = None
    if category:
        category_data = {
            "id": category.id,
            "name": category.name,
            "description": category.description,
            "icon_name": category.icon_name,
            "color_hex": category.color_hex,
            "examples": category.examples,
            "disposal_guide": category.disposal_guide
        }

    result = {
        "label": label,
        "confidence": top_score,
        "image_url": image_url,
        "scores": {CLASS_NAMES[i]: float(predictions[i]) for i in range(len(CLASS_NAMES))},
        "category": category_data
    }
    return JSONResponse(content=result)
