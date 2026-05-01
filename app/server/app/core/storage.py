import io
import uuid
from datetime import timedelta
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

BUCKET_NAME = "garbage-images"
AVATAR_BUCKET_NAME = "avatars"

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

def upload_image_to_minio(image_bytes: bytes, content_type: str = "image/jpeg") -> str:
    """Uploads an image to MinIO and returns the URL."""
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
        
        # Return the public URL for the image via Nginx
        protocol = "https" if settings.minio_secure else "http"
        return f"{protocol}://{settings.public_minio_endpoint}/{BUCKET_NAME}/{file_name}"
    except S3Error as err:
        print(f"Failed to upload image to MinIO: {err}")
        return ""

def generate_avatar_presigned_url(user_id: int, content_type: str = "image/jpeg") -> dict:
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

    # The presigned URL points to internal MinIO host; replace with public host for mobile
    protocol = "https" if settings.minio_secure else "http"
    internal_host = settings.minio_endpoint          # e.g. "minio:9000"
    public_host = settings.public_minio_endpoint      # e.g. "192.168.1.x"
    upload_url = presigned_url.replace(f"http://{internal_host}", f"{protocol}://{public_host}", 1)

    public_url = f"{protocol}://{public_host}/{AVATAR_BUCKET_NAME}/{object_name}"

    return {
        "upload_url": upload_url,
        "public_url": public_url,
        "object_name": object_name,
    }
