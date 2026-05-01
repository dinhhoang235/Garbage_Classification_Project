import io
import uuid
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

def init_minio():
    """Ensure the bucket exists on startup."""
    try:
        if not minio_client.bucket_exists(BUCKET_NAME):
            minio_client.make_bucket(BUCKET_NAME)
            
            # Make the bucket public for reading images
            policy = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {"AWS": ["*"]},
                        "Action": ["s3:GetObject"],
                        "Resource": [f"arn:aws:s3:::{BUCKET_NAME}/*"]
                    }
                ]
            }
            import json
            minio_client.set_bucket_policy(BUCKET_NAME, json.dumps(policy))
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
