import io
import uuid
from datetime import timedelta
from urllib.parse import urlparse
from minio import Minio
from minio.error import S3Error
from app.core.config import settings

# Initialize MinIO client
minio_client = Minio(
    settings.minio_endpoint,
    access_key=settings.minio_root_user,
    secret_key=settings.minio_root_password,
    secure=settings.minio_secure
)

BUCKET_NAME = settings.minio_bucket
AVATAR_BUCKET_NAME = settings.minio_avatar_bucket

def _ensure_public_bucket(bucket_name: str) -> None:
    """Create bucket if not exists and set public-read policy."""
    import json
    if not minio_client.bucket_exists(bucket_name):
        minio_client.make_bucket(bucket_name)
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": ["*"]},
                "Action": ["s3:GetObject"],
                "Resource": [f"arn:aws:s3:::{bucket_name}/*"]
            }
        ]
    }
    minio_client.set_bucket_policy(bucket_name, json.dumps(policy))

def init_minio():
    """Ensure required buckets exist on startup."""
    try:
        _ensure_public_bucket(BUCKET_NAME)
        _ensure_public_bucket(AVATAR_BUCKET_NAME)
    except S3Error as err:
        print(f"MinIO init error: {err}")


def normalize_public_image_reference(image_ref: str | None) -> str | None:
    """Normalize image reference to a stable bucket/object path.

    Examples:
    - /garbage-images/abc.jpg -> garbage-images/abc.jpg
    - garbage-images/abc.jpg -> garbage-images/abc.jpg
    """
    if not image_ref:
        return None

    ref = image_ref.strip()
    if not ref:
        return None

    if ref.startswith(f"{BUCKET_NAME}/"):
        return ref

    if ref.startswith("http://") or ref.startswith("https://"):
        parsed = urlparse(ref)
        path = parsed.path.lstrip("/")
        return path or None

    return ref.lstrip("/")


def build_public_image_url(image_ref: str | None, public_base_url: str | None = None) -> str | None:
    """Return a client-safe relative path from stored bucket/object path."""
    normalized = normalize_public_image_reference(image_ref)
    if not normalized:
        return None

    return f"/{normalized}"


def upload_image_to_minio(image_bytes: bytes, content_type: str = "image/jpeg") -> str:
    """Uploads an image to MinIO and returns stable bucket/object path."""
    try:
        file_name = f"{uuid.uuid4().hex}.jpg"
        data_stream = io.BytesIO(image_bytes)
        length = len(image_bytes)
        
        minio_client.put_object(
            bucket_name=BUCKET_NAME,
            object_name=file_name,
            data=data_stream,
            length=length,
            content_type=content_type
        )

        # Persist only relative object path so data remains valid across IP/network changes.
        return f"{BUCKET_NAME}/{file_name}"
    except S3Error as err:
        print(f"Failed to upload image to MinIO: {err}")
        return ""

def generate_avatar_presigned_url(
    user_id: int,
    content_type: str = "image/jpeg",
    public_base_url: str | None = None,
) -> dict:
    """
    Generate a presigned PUT URL so the client can upload avatar directly to MinIO.
    Returns dict with:
      - upload_url: presigned PUT URL (valid 15 min)
      - public_url: the final public URL of the avatar after upload
      - object_name: object key in the bucket
    """
    ext = "jpg" if "jpeg" in content_type else content_type.split("/")[-1]
    object_name = f"user_{user_id}/{uuid.uuid4().hex}.{ext}"

    presigned_url = minio_client.presigned_put_object(
        bucket_name=AVATAR_BUCKET_NAME,
        object_name=object_name,
        expires=timedelta(minutes=15),
    )

    # Build public URLs from request host when provided to avoid hardcoded IPs.
    if public_base_url:
        base = public_base_url.rstrip("/")
    else:
        protocol = "https" if settings.minio_secure else "http"
        base = f"{protocol}://{settings.public_minio_endpoint}"

    parsed = urlparse(presigned_url)
    query = f"?{parsed.query}" if parsed.query else ""
    upload_url = f"{base}{parsed.path}{query}"
    public_url = f"/{AVATAR_BUCKET_NAME}/{object_name}"

    return {
        "upload_url": upload_url,
        "public_url": public_url,
        "object_name": object_name,
    }
